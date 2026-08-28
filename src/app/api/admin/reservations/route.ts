import { db } from '@/lib/db'
import { ok, fail, handleError, unauthorized, forbidden, genRef } from '@/lib/api'
import { getSession } from '@/lib/auth'
import { Decimal } from '@prisma/client/runtime/library'

export const dynamic = 'force-dynamic'

// GET /api/admin/reservations — list with filters
export async function GET(req: Request) {
  return handleError(async () => {
    const s = await getSession()
    if (!s) return unauthorized()
    const { searchParams } = new URL(req.url)
    const status = searchParams.get('status') || ''
    const q = searchParams.get('q') || ''
    const page = parseInt(searchParams.get('page') || '1')
    const pageSize = parseInt(searchParams.get('pageSize') || '50')

    const where: Record<string, unknown> = {}
    if (status) where.bookingStatus = status
    if (q) {
      where.OR = [
        { confirmationNo: { contains: q, mode: 'insensitive' } },
        { guest: { name: { contains: q, mode: 'insensitive' } } },
        { guest: { phone: { contains: q } } },
      ]
    }

    const [total, items] = await Promise.all([
      db.reservation.count({ where }),
      db.reservation.findMany({
        where, include: { guest: true, roomType: true, room: true, payments: true, bookingRequest: true, createdBy: { select: { name: true } } },
        orderBy: { createdAt: 'desc' }, skip: (page - 1) * pageSize, take: pageSize,
      }),
    ])
    return ok({
      total, page, pageSize,
      items: items.map(r => ({
        id: r.id, confirmationNo: r.confirmationNo,
        guestName: r.guest.name, guestPhone: r.guest.phone, guestWhatsapp: r.guest.whatsapp,
        roomType: r.roomType.nameAr, roomNumber: r.room?.number || null,
        checkIn: r.checkIn, checkOut: r.checkOut, nights: r.nights,
        adults: r.adults, children: r.children,
        total: Number(r.totalSnapshot), paid: Number(r.paidAmount), remaining: Number(r.remainingAmount),
        currency: r.currency,
        paymentStatus: r.paymentStatus, bookingStatus: r.bookingStatus,
        source: r.source, createdAt: r.createdAt,
        createdBy: r.createdBy?.name || null,
      })),
    })
  })
}

// POST /api/admin/reservations — create reservation (admin on behalf of guest, or from booking request)
export async function POST(req: Request) {
  return handleError(async () => {
    const s = await getSession()
    if (!s) return unauthorized()
    const body = await req.json().catch(() => ({}))
    const { guestName, guestPhone, guestWhatsapp, roomTypeId, checkIn, checkOut, adults = 1, children = 0, source = 'admin', bookingRequestId, assignRoomId, createdReason } = body as Record<string, string | number>

    if (!guestName || !guestPhone || !roomTypeId || !checkIn || !checkOut) return fail('بيانات ناقصة', 400)
    const ci = new Date(checkIn as string), co = new Date(checkOut as string)
    if (co <= ci) return fail('تواريخ غير صحيحة', 400)
    const nights = Math.round((co.getTime() - ci.getTime()) / 86400000)

    const rt = await db.roomType.findUnique({ where: { id: roomTypeId as string }, include: { rooms: true, offerRooms: { include: { offer: true } } } })
    if (!rt) return fail('نوع الغرفة غير موجود', 404)

    // Check availability
    const confirmedStatuses = ['confirmed', 'checked_in', 'checked_out', 'awaiting_confirmation']
    const overlapping = await db.reservation.findMany({
      where: { bookingStatus: { in: confirmedStatuses }, roomTypeId: rt.id, OR: [{ checkIn: { lt: co }, checkOut: { gt: ci } }] },
      select: { roomId: true },
    })
    const reservedIds = new Set(overlapping.filter(o => o.roomId).map(o => o.roomId))
    const blockedStatuses = ['maintenance', 'blocked', 'out_of_service']
    let room = assignRoomId ? rt.rooms.find(r => r.id === assignRoomId) : null
    if (!room) {
      room = rt.rooms.find(r => !blockedStatuses.includes(r.status) && !reservedIds.has(r.id)) || null
    }
    if (!room) return fail('لا توجد غرفة متاحة لهذا النوع في التواريخ المحددة', 409)

    // Pricing snapshot
    const base = Number(rt.basePrice)
    let subtotal = base * nights
    let discount = 0
    const now = new Date()
    let appliedOffer = null
    for (const or of rt.offerRooms) {
      const o = or.offer
      if (o.status !== 'published' || now < o.startsAt || now > o.endsAt) continue
      let d = o.discountType === 'percentage' ? subtotal * Number(o.discountValue) / 100 : Number(o.discountValue) * nights
      if (d > discount) { discount = d; appliedOffer = o }
    }
    const total = subtotal - discount
    const remaining = total

    // upsert guest
    let guest = await db.guest.findFirst({ where: { phone: guestPhone as string } })
    if (!guest) guest = await db.guest.create({ data: { name: guestName as string, phone: guestPhone as string, whatsapp: (guestWhatsapp as string) || null } })
    else if (guest.name !== guestName || (guestWhatsapp && guest.whatsapp !== guestWhatsapp)) {
      guest = await db.guest.update({ where: { id: guest.id }, data: { name: guestName as string, whatsapp: (guestWhatsapp as string) || guest.whatsapp } })
    }

    const confirmationNo = genRef('CHH')

    // Transaction: create reservation, mark booking request converted, set room reserved, audit
    const reservation = await db.reservation.create({
      data: {
        confirmationNo,
        guestId: guest.id,
        roomTypeId: rt.id,
        roomId: room.id,
        checkIn: ci, checkOut: co, nights,
        adults: Number(adults) || 1, children: Number(children) || 0,
        roomPriceSnapshot: new Decimal(subtotal),
        discountSnapshot: new Decimal(discount),
        servicesSnapshot: new Decimal(0),
        feesSnapshot: new Decimal(0),
        totalSnapshot: new Decimal(total),
        currency: rt.currency,
        paidAmount: new Decimal(0),
        remainingAmount: new Decimal(remaining),
        paymentStatus: 'pending',
        bookingStatus: 'awaiting_confirmation',
        source: source as string,
        createdById: s.id,
        createdReason: (createdReason as string) || null,
        bookingRequestId: (bookingRequestId as string) || null,
      },
      include: { guest: true, roomType: true, room: true },
    })

    // If from booking request, mark converted
    if (bookingRequestId) {
      await db.bookingRequest.update({ where: { id: bookingRequestId as string }, data: { status: 'converted' } })
    }

    await db.auditLog.create({
      data: {
        actorId: s.id, action: 'reservation.create', entity: 'reservation', entityId: reservation.id,
        newValue: JSON.stringify({ confirmationNo, roomType: rt.slug, checkIn: checkIn, checkOut: checkOut, total }),
        reason: (createdReason as string) || null,
      },
    })

    await db.notification.create({
      data: {
        titleAr: 'حجز جديد', titleEn: 'New Reservation',
        bodyAr: `${confirmationNo} - ${guestName} - ${rt.nameAr}`,
        bodyEn: `${confirmationNo} - ${guestName} - ${rt.nameEn}`,
        link: '/admin/reservations', category: 'reservation',
      },
    }).catch(() => {})

    return ok({
      id: reservation.id, confirmationNo,
      guestName: reservation.guest.name, guestPhone: reservation.guest.phone,
      roomType: reservation.roomType.nameAr, roomNumber: reservation.room?.number,
      checkIn: reservation.checkIn, checkOut: reservation.checkOut, nights: reservation.nights,
      total, paid: 0, remaining,
      paymentStatus: reservation.paymentStatus, bookingStatus: reservation.bookingStatus,
      appliedOffer: appliedOffer ? { slug: appliedOffer.slug, nameAr: appliedOffer.nameAr } : null,
    })
  })
}

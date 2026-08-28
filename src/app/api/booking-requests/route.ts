import { db } from '@/lib/db'
import { ok, fail, handleError, genRef } from '@/lib/api'

export const dynamic = 'force-dynamic'

// POST /api/booking-requests — guest creates a booking request
// body: { roomTypeId, checkIn, checkOut, adults, children, guestName, guestPhone, guestWhatsapp?, message?, channel? }
export async function POST(req: Request) {
  return handleError(async () => {
    const body = await req.json().catch(() => ({}))
    const { roomTypeId, checkIn, checkOut, adults = 1, children = 0, guestName, guestPhone, guestWhatsapp, message, channel = 'app' } = body as Record<string, string | number>

    if (!guestName || !guestPhone) return fail('الاسم ورقم الهاتف مطلوبان', 400)
    if (!checkIn || !checkOut) return fail('التواريخ مطلوبة', 400)
    const ci = new Date(checkIn as string)
    const co = new Date(checkOut as string)
    if (isNaN(ci.getTime()) || isNaN(co.getTime()) || co <= ci) return fail('تواريخ غير صحيحة', 400)
    const nights = Math.round((co.getTime() - ci.getTime()) / 86400000)
    if (nights < 1) return fail('الحد الأدنى للإقامة ليلة واحدة', 400)

    // upsert guest by phone (phone is the guest identifier)
    let guest = await db.guest.findFirst({ where: { phone: guestPhone as string } })
    if (!guest) {
      guest = await db.guest.create({
        data: { name: guestName as string, phone: guestPhone as string, whatsapp: (guestWhatsapp as string) || null },
      })
    } else if (guest.name !== guestName || (guestWhatsapp && guest.whatsapp !== guestWhatsapp)) {
      guest = await db.guest.update({
        where: { id: guest.id },
        data: { name: guestName as string, whatsapp: (guestWhatsapp as string) || guest.whatsapp },
      })
    }

    const rt = roomTypeId ? await db.roomType.findUnique({ where: { id: roomTypeId as string } }) : null

    const reference = genRef('BR')
    const br = await db.bookingRequest.create({
      data: {
        reference,
        guestId: guest.id,
        roomTypeId: rt?.id || null,
        checkIn: ci,
        checkOut: co,
        adults: Number(adults) || 1,
        children: Number(children) || 0,
        nights,
        guestName: guestName as string,
        guestPhone: guestPhone as string,
        guestWhatsapp: (guestWhatsapp as string) || null,
        message: (message as string) || null,
        status: 'new',
        priority: 'normal',
        channel: channel as string,
      },
      include: { roomType: true, guest: true },
    })

    // Create a notification for admins
    await db.notification.create({
      data: {
        titleAr: 'طلب حجز جديد',
        titleEn: 'New Booking Request',
        bodyAr: `طلب ${reference} من ${guestName}`,
        bodyEn: `Request ${reference} from ${guestName}`,
        link: `/admin/communication`,
        category: 'booking_request',
      },
    }).catch(() => {})

    // Calculate price snapshot for display
    const basePrice = rt ? Number(rt.basePrice) : 0
    const subtotal = basePrice * nights
    const total = subtotal // offers applied at confirmation

    return ok({
      reference: br.reference,
      id: br.id,
      checkIn: br.checkIn,
      checkOut: br.checkOut,
      nights,
      guestName: br.guestName,
      guestPhone: br.guestPhone,
      roomType: rt ? { id: rt.id, nameAr: rt.nameAr, nameEn: rt.nameEn, basePrice } : null,
      estimatedTotal: total,
      currency: rt?.currency || 'YER',
      status: br.status,
      createdAt: br.createdAt,
    })
  })
}

// GET /api/booking-requests?phone=XXX — lookup guest's requests by phone
export async function GET(req: Request) {
  return handleError(async () => {
    const { searchParams } = new URL(req.url)
    const phone = searchParams.get('phone') || ''
    const reference = searchParams.get('reference') || ''
    if (!phone && !reference) return fail('مطلوب: phone أو reference', 400)

    let requests
    if (reference) {
      requests = await db.bookingRequest.findMany({
        where: { reference },
        include: { roomType: true, reservation: true },
        orderBy: { createdAt: 'desc' },
      })
    } else {
      requests = await db.bookingRequest.findMany({
        where: { guestPhone: phone },
        include: { roomType: true, reservation: true },
        orderBy: { createdAt: 'desc' },
      })
    }
    return ok(requests.map(r => ({
      reference: r.reference, status: r.status, priority: r.priority,
      checkIn: r.checkIn, checkOut: r.checkOut, nights: r.nights,
      adults: r.adults, children: r.children,
      guestName: r.guestName, guestPhone: r.guestPhone,
      message: r.message, channel: r.channel, createdAt: r.createdAt,
      roomType: r.roomType ? { id: r.roomType.id, nameAr: r.roomType.nameAr, nameEn: r.roomType.nameEn, basePrice: Number(r.roomType.basePrice), imageUrl: r.roomType.imageUrl } : null,
      reservation: r.reservation ? { confirmationNo: r.reservation.confirmationNo, bookingStatus: r.reservation.bookingStatus, paymentStatus: r.reservation.paymentStatus, total: Number(r.reservation.totalSnapshot), paid: Number(r.reservation.paidAmount) } : null,
    })))
  })
}

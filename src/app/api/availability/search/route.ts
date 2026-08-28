import { db } from '@/lib/db'
import { ok, fail, handleError, dec } from '@/lib/api'

export const dynamic = 'force-dynamic'

// POST /api/availability/search
// body: { checkIn: 'YYYY-MM-DD', checkOut: 'YYYY-MM-DD', adults?: number, children?: number, roomTypeId?: string }
// returns: [{ roomType, availableRooms: count, pricePerNight, nights, subtotal, discount, total, currency }]
export async function POST(req: Request) {
  return handleError(async () => {
    const body = await req.json().catch(() => ({}))
    const { checkIn, checkOut, adults = 1, children = 0, roomTypeId } = body as {
      checkIn: string; checkOut: string; adults?: number; children?: number; roomTypeId?: string
    }
    if (!checkIn || !checkOut) return fail('التواريخ مطلوبة', 400)
    const ci = new Date(checkIn)
    const co = new Date(checkOut)
    if (isNaN(ci.getTime()) || isNaN(co.getTime())) return fail('تواريخ غير صحيحة', 400)
    if (co <= ci) return fail('تاريخ المغادرة يجب أن يكون بعد الوصول', 400)
    const nights = Math.round((co.getTime() - ci.getTime()) / 86400000)
    if (nights < 1) return fail('الحد الأدنى للإقامة ليلة واحدة', 400)

    // Get all published room types (or filtered)
    const types = await db.roomType.findMany({
      where: { status: 'published', ...(roomTypeId ? { id: roomTypeId } : {}) },
      orderBy: { sortOrder: 'asc' },
      include: { rooms: true, offerRooms: { include: { offer: true } } },
    })

    // Find conflicting reservations (confirmed states overlapping dates)
    const confirmedStatuses = ['confirmed', 'checked_in', 'checked_out', 'awaiting_confirmation']
    const overlapping = await db.reservation.findMany({
      where: {
        bookingStatus: { in: confirmedStatuses },
        OR: [
          { checkIn: { lt: co }, checkOut: { gt: ci } },
        ],
      },
      select: { roomTypeId: true, roomId: true, checkIn: true, checkOut: true },
    })

    // Room maintenance / blocked status
    const blockedRoomStatuses = ['maintenance', 'blocked', 'out_of_service']

    const now = new Date()
    const results = []
    for (const rt of types) {
      const totalRooms = rt.rooms.length
      const blockedRooms = rt.rooms.filter(r => blockedRoomStatuses.includes(r.status)).length
      const reservedRoomIds = new Set(
        overlapping.filter(o => o.roomTypeId === rt.id && o.roomId).map(o => o.roomId)
      )
      const availableRooms = rt.rooms.filter(r =>
        !blockedRoomStatuses.includes(r.status) && !reservedRoomIds.has(r.id)
      ).length

      // Pricing: base * nights, apply best offer
      const base = dec(rt.basePrice)
      let subtotal = base * nights
      let bestDiscount = 0
      let bestOffer = null
      for (const or of rt.offerRooms) {
        const o = or.offer
        if (o.status !== 'published') continue
        if (now < o.startsAt || now > o.endsAt) continue
        let d = 0
        if (o.discountType === 'percentage') d = subtotal * dec(o.discountValue) / 100
        else d = dec(o.discountValue) * nights
        if (d > bestDiscount) { bestDiscount = d; bestOffer = o }
      }
      const total = subtotal - bestDiscount

      results.push({
        roomType: {
          id: rt.id, slug: rt.slug,
          nameAr: rt.nameAr, nameEn: rt.nameEn,
          descriptionAr: rt.descriptionAr, descriptionEn: rt.descriptionEn,
          basePrice: base, currency: rt.currency,
          capacity: rt.capacity, beds: rt.beds, size: rt.size,
          amenities: JSON.parse(rt.amenitiesJson || '[]'),
          imageUrl: rt.imageUrl,
        },
        availableRooms,
        totalRooms,
        blockedRooms,
        pricePerNight: base,
        nights,
        subtotal,
        discount: bestDiscount,
        total,
        currency: rt.currency,
        appliedOffer: bestOffer ? { id: bestOffer.id, slug: bestOffer.slug, nameAr: bestOffer.nameAr, nameEn: bestOffer.nameEn, discountType: bestOffer.discountType, discountValue: dec(bestOffer.discountValue) } : null,
      })
    }

    return ok({ checkIn, checkOut, adults, children, nights, results })
  })
}

import { db } from '@/lib/db'
import { ok, fail, handleError, genRef } from '@/lib/api'

export const dynamic = 'force-dynamic'

// POST /api/service-requests — guest/staff creates a service request
export async function POST(req: Request) {
  return handleError(async () => {
    const body = await req.json().catch(() => ({}))
    const { guestName, guestPhone, roomId, reservationId, serviceId, category, description, priority = 'normal' } = body as Record<string, string>

    if (!description) return fail('الوصف مطلوب', 400)

    let guestId: string | undefined
    if (guestPhone) {
      let g = await db.guest.findFirst({ where: { phone: guestPhone } })
      if (!g) g = await db.guest.create({ data: { name: guestName || guestPhone, phone: guestPhone } })
      guestId = g.id
    }

    const sr = await db.serviceRequest.create({
      data: {
        reference: genRef('SR'),
        guestId: guestId || null,
        reservationId: reservationId || null,
        roomId: roomId || null,
        serviceId: serviceId || null,
        category: category || 'general',
        descriptionAr: description,
        priority,
        status: 'new',
      },
      include: { service: true, room: true, guest: true },
    })

    await db.notification.create({
      data: {
        titleAr: 'طلب خدمة جديد',
        titleEn: 'New Service Request',
        bodyAr: `${sr.reference} - ${description.slice(0, 50)}`,
        bodyEn: `${sr.reference} - ${description.slice(0, 50)}`,
        link: '/admin/service-requests',
        category: 'service_request',
      },
    }).catch(() => {})

    return ok({ reference: sr.reference, id: sr.id, status: sr.status, createdAt: sr.createdAt })
  })
}

// GET /api/service-requests?phone=XXX — lookup guest's service requests
export async function GET(req: Request) {
  return handleError(async () => {
    const { searchParams } = new URL(req.url)
    const phone = searchParams.get('phone')
    const reference = searchParams.get('reference')
    if (!phone && !reference) return fail('مطلوب: phone أو reference', 400)

    const where = reference
      ? { reference }
      : { guest: { phone: phone! } }
    const list = await db.serviceRequest.findMany({
      where, include: { service: true, room: true }, orderBy: { createdAt: 'desc' },
    })
    return ok(list.map(s => ({
      reference: s.reference, status: s.status, priority: s.priority,
      category: s.category, descriptionAr: s.descriptionAr,
      createdAt: s.createdAt, completedAt: s.completedAt,
      service: s.service ? { nameAr: s.service.nameAr, price: Number(s.service.price) } : null,
      room: s.room ? { number: s.room.number } : null,
    })))
  })
}

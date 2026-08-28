import { db } from '@/lib/db'
import { ok, fail, handleError, unauthorized } from '@/lib/api'
import { getSession } from '@/lib/auth'

export const dynamic = 'force-dynamic'

// GET /api/admin/communication — contact requests + booking requests (communication center)
export async function GET(req: Request) {
  return handleError(async () => {
    const s = await getSession()
    if (!s) return unauthorized()
    const { searchParams } = new URL(req.url)
    const status = searchParams.get('status') || ''

    const [contactRequests, bookingRequests] = await Promise.all([
      db.contactRequest.findMany({
        where: status ? { status } : {},
        include: { guest: true, owner: { select: { name: true } }, reservation: { select: { confirmationNo: true } } },
        orderBy: { lastActivityAt: 'desc' }, take: 100,
      }),
      db.bookingRequest.findMany({
        where: status ? { status } : {},
        include: { guest: true, roomType: true, owner: { select: { name: true } }, reservation: { select: { confirmationNo: true } } },
        orderBy: { createdAt: 'desc' }, take: 100,
      }),
    ])

    return ok({
      contactRequests: contactRequests.map(c => ({
        id: c.id, reference: c.reference, status: c.status, priority: c.priority,
        guestName: c.guestName, guestPhone: c.guestPhone, channel: c.channel,
        subject: c.subject, message: c.message,
        owner: c.owner?.name || null, reservationNo: c.reservation?.confirmationNo || null,
        createdAt: c.createdAt, lastActivityAt: c.lastActivityAt,
      })),
      bookingRequests: bookingRequests.map(b => ({
        id: b.id, reference: b.reference, status: b.status, priority: b.priority,
        guestName: b.guestName, guestPhone: b.guestPhone, guestWhatsapp: b.guestWhatsapp,
        checkIn: b.checkIn, checkOut: b.checkOut, nights: b.nights, adults: b.adults, children: b.children,
        message: b.message, channel: b.channel,
        roomType: b.roomType ? { id: b.roomType.id, nameAr: b.roomType.nameAr, basePrice: Number(b.roomType.basePrice) } : null,
        owner: b.owner?.name || null, reservationNo: b.reservation?.confirmationNo || null,
        createdAt: b.createdAt,
      })),
    })
  })
}

// PATCH /api/admin/communication — { kind: contact|booking, id, action, reason? }
export async function PATCH(req: Request) {
  return handleError(async () => {
    const s = await getSession()
    if (!s) return unauthorized()
    const { kind, id, action, ownerId, reason } = await req.json().catch(() => ({}))
    if (!kind || !id || !action) return fail('kind و id و action مطلوبة', 400)

    const actionToStatus: Record<string, string> = {
      assign: 'assigned', contact: 'contacted', wait_customer: 'waiting_customer',
      wait_hotel: 'waiting_hotel', confirm: 'confirmed', convert: 'converted',
      close: 'closed', cancel: 'cancelled',
    }
    const newStatus = actionToStatus[action]
    if (!newStatus) return fail('إجراء غير معروف', 400)

    if (kind === 'contact') {
      const existing = await db.contactRequest.findUnique({ where: { id } })
      if (!existing) return fail('الطلب غير موجود', 404)
      const updated = await db.contactRequest.update({ where: { id }, data: { status: newStatus, ownerId: ownerId || existing.ownerId, lastActivityAt: new Date() } })
      await db.auditLog.create({ data: { actorId: s.id, action: `contact_request.${action}`, entity: 'contact_request', entityId: id, oldValue: existing.status, newValue: newStatus, reason: reason || null } })
      return ok({ id: updated.id, status: updated.status })
    } else if (kind === 'booking') {
      const existing = await db.bookingRequest.findUnique({ where: { id } })
      if (!existing) return fail('الطلب غير موجود', 404)
      const updated = await db.bookingRequest.update({ where: { id }, data: { status: newStatus, ownerId: ownerId || existing.ownerId } })
      await db.auditLog.create({ data: { actorId: s.id, action: `booking_request.${action}`, entity: 'booking_request', entityId: id, oldValue: existing.status, newValue: newStatus, reason: reason || null } })
      return ok({ id: updated.id, status: updated.status })
    }
    return fail('نوع غير معروف', 400)
  })
}

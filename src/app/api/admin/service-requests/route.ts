import { db } from '@/lib/db'
import { ok, fail, handleError, unauthorized } from '@/lib/api'
import { getSession } from '@/lib/auth'
import { Decimal } from '@prisma/client/runtime/library'

export const dynamic = 'force-dynamic'

// GET /api/admin/service-requests?status=
export async function GET(req: Request) {
  return handleError(async () => {
    const s = await getSession()
    if (!s) return unauthorized()
    const { searchParams } = new URL(req.url)
    const status = searchParams.get('status') || ''
    const where: Record<string, unknown> = {}
    if (status) where.status = status
    const items = await db.serviceRequest.findMany({
      where, include: { service: true, room: true, guest: true, assignedTo: { select: { name: true } }, reservation: true },
      orderBy: { createdAt: 'desc' },
    })
    return ok(items.map(x => ({
      id: x.id, reference: x.reference, status: x.status, priority: x.priority,
      category: x.category, descriptionAr: x.descriptionAr,
      createdAt: x.createdAt, completedAt: x.completedAt,
      guest: x.guest ? { id: x.guest.id, name: x.guest.name, phone: x.guest.phone } : null,
      room: x.room ? { id: x.room.id, number: x.room.number } : null,
      service: x.service ? { id: x.service.id, nameAr: x.service.nameAr, price: Number(x.service.price) } : null,
      assignedTo: x.assignedTo?.name || null,
    })))
  })
}

// PATCH /api/admin/service-requests — { id, action: assign|accept|start|wait|complete|cancel|reject, assignedToId?, reason? }
export async function PATCH(req: Request) {
  return handleError(async () => {
    const s = await getSession()
    if (!s) return unauthorized()
    const { id, action, assignedToId, reason } = await req.json().catch(() => ({}))
    if (!id || !action) return fail('id و action مطلوبان', 400)
    const existing = await db.serviceRequest.findUnique({ where: { id } })
    if (!existing) return fail('الطلب غير موجود', 404)
    const actionToStatus: Record<string, string> = {
      accept: 'accepted', assign: 'assigned', start: 'in_progress',
      wait: 'waiting', complete: 'completed', cancel: 'cancelled', reject: 'rejected',
    }
    const newStatus = actionToStatus[action]
    if (!newStatus) return fail('إجراء غير معروف', 400)
    const data: Record<string, unknown> = { status: newStatus }
    if (assignedToId) data.assignedToId = assignedToId
    if (newStatus === 'completed') data.completedAt = new Date()
    const updated = await db.serviceRequest.update({ where: { id }, data })
    await db.auditLog.create({ data: { actorId: s.id, action: `service_request.${action}`, entity: 'service_request', entityId: id, oldValue: existing.status, newValue: newStatus, reason: reason || null } })
    return ok({ id: updated.id, status: updated.status })
  })
}

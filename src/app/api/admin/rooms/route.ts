import { db } from '@/lib/db'
import { ok, fail, handleError, unauthorized } from '@/lib/api'
import { getSession } from '@/lib/auth'

export const dynamic = 'force-dynamic'

// GET /api/admin/rooms
export async function GET(req: Request) {
  return handleError(async () => {
    const s = await getSession()
    if (!s) return unauthorized()
    const { searchParams } = new URL(req.url)
    const status = searchParams.get('status') || ''
    const q = searchParams.get('q') || ''

    const where: Record<string, unknown> = {}
    if (status) where.status = status
    if (q) where.number = { contains: q }

    const rooms = await db.room.findMany({
      where, include: { roomType: true, housekeepingTasks: { where: { status: 'pending' }, take: 1 } },
      orderBy: [{ floor: 'asc' }, { number: 'asc' }],
    })
    return ok(rooms.map(r => ({
      id: r.id, number: r.number, floor: r.floor, status: r.status,
      notes: r.notes, lastCleanedAt: r.lastCleanedAt,
      roomType: { id: r.roomType.id, nameAr: r.roomType.nameAr, nameEn: r.roomType.nameEn, basePrice: Number(r.roomType.basePrice) },
      hasPendingTask: r.housekeepingTasks.length > 0,
    })))
  })
}

// PATCH /api/admin/rooms — update status { id, status, reason? }
export async function PATCH(req: Request) {
  return handleError(async () => {
    const s = await getSession()
    if (!s) return unauthorized()
    const { id, status, reason } = await req.json().catch(() => ({}))
    if (!id || !status) return fail('id و status مطلوبان', 400)
    const valid = ['available','reserved','occupied','cleaning','maintenance','blocked','out_of_service']
    if (!valid.includes(status)) return fail('حالة غير صحيحة', 400)

    const room = await db.room.findUnique({ where: { id } })
    if (!room) return fail('الغرفة غير موجودة', 404)
    const old = room.status
    const updated = await db.room.update({ where: { id }, data: { status, lastCleanedAt: status === 'available' ? new Date() : room.lastCleanedAt } })
    await db.auditLog.create({ data: { actorId: s.id, action: 'room.status_change', entity: 'room', entityId: id, oldValue: old, newValue: status, reason: reason || null } })
    return ok({ id: updated.id, status: updated.status })
  })
}

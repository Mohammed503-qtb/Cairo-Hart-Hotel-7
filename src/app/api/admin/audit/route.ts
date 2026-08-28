import { db } from '@/lib/db'
import { ok, handleError, unauthorized } from '@/lib/api'
import { getSession } from '@/lib/auth'

export const dynamic = 'force-dynamic'

// GET /api/admin/audit?entity=&limit=
export async function GET(req: Request) {
  return handleError(async () => {
    const s = await getSession()
    if (!s) return unauthorized()
    const { searchParams } = new URL(req.url)
    const entity = searchParams.get('entity') || ''
    const limit = Math.min(parseInt(searchParams.get('limit') || '100'), 500)
    const where: Record<string, unknown> = {}
    if (entity) where.entity = entity
    const logs = await db.auditLog.findMany({
      where, take: limit, orderBy: { createdAt: 'desc' },
      include: { actor: { select: { name: true } } },
    })
    return ok(logs.map(l => ({
      id: l.id, actor: l.actor?.name || 'نظام', action: l.action,
      entity: l.entity, entityId: l.entityId,
      oldValue: l.oldValue, newValue: l.newValue, reason: l.reason,
      createdAt: l.createdAt,
    })))
  })
}

import { db } from '@/lib/db'
import { ok, handleError, unauthorized } from '@/lib/api'
import { getSession } from '@/lib/auth'

export const dynamic = 'force-dynamic'

// GET /api/admin/users
export async function GET() {
  return handleError(async () => {
    const s = await getSession()
    if (!s) return unauthorized()
    if (!s.roles.includes('admin')) return unauthorized()
    const users = await db.user.findMany({
      orderBy: { createdAt: 'desc' },
      include: { roles: { include: { role: true } } },
    })
    return ok(users.map(u => ({
      id: u.id, email: u.email, name: u.name, phone: u.phone, status: u.status,
      roles: u.roles.map(r => r.role.key),
      roleNames: u.roles.map(r => r.role.nameAr),
      createdAt: u.createdAt,
    })))
  })
}

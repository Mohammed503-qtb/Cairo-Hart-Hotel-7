import { db } from '@/lib/db'
import { ok, handleError, unauthorized } from '@/lib/api'
import { getSession } from '@/lib/auth'

export const dynamic = 'force-dynamic'

// GET /api/admin/guests?q=&page=
export async function GET(req: Request) {
  return handleError(async () => {
    const s = await getSession()
    if (!s) return unauthorized()
    const { searchParams } = new URL(req.url)
    const q = searchParams.get('q') || ''
    const page = parseInt(searchParams.get('page') || '1')
    const pageSize = 50
    const where: Record<string, unknown> = {}
    if (q) {
      where.OR = [
        { name: { contains: q, mode: 'insensitive' } },
        { phone: { contains: q } },
      ]
    }
    const [total, guests] = await Promise.all([
      db.guest.count({ where }),
      db.guest.findMany({
        where, orderBy: { createdAt: 'desc' }, skip: (page - 1) * pageSize, take: pageSize,
        include: { _count: { select: { reservations: true, bookingRequests: true } } },
      }),
    ])
    return ok({
      total, page, pageSize,
      guests: guests.map(g => ({
        id: g.id, name: g.name, phone: g.phone, whatsapp: g.whatsapp, email: g.email,
        notes: g.notes, blacklisted: g.blacklisted, createdAt: g.createdAt,
        reservationsCount: g._count.reservations, requestsCount: g._count.bookingRequests,
      })),
    })
  })
}

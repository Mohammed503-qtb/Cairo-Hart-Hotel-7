import { db } from '@/lib/db'
import { ok, fail, handleError, unauthorized } from '@/lib/api'
import { getSession } from '@/lib/auth'
import { Decimal } from '@prisma/client/runtime/library'

export const dynamic = 'force-dynamic'

// GET /api/admin/services
export async function GET() {
  return handleError(async () => {
    const s = await getSession()
    if (!s) return unauthorized()
    const items = await db.service.findMany({ orderBy: { sortOrder: 'asc' } })
    return ok(items.map(x => ({ ...x, price: Number(x.price) })))
  })
}

// POST /api/admin/services — create
export async function POST(req: Request) {
  return handleError(async () => {
    const s = await getSession()
    if (!s) return unauthorized()
    const b = await req.json().catch(() => ({}))
    const { slug, nameAr, nameEn, descriptionAr, descriptionEn, price = 0, category = 'general', imageUrl, status = 'published' } = b as Record<string, string | number>
    if (!slug || !nameAr || !nameEn) return fail('بيانات ناقصة', 400)
    const svc = await db.service.create({
      data: {
        slug: slug as string, nameAr: nameAr as string, nameEn: nameEn as string,
        descriptionAr: (descriptionAr as string) || null, descriptionEn: (descriptionEn as string) || null,
        price: new Decimal(Number(price)), category: category as string,
        imageUrl: (imageUrl as string) || null, status: status as string,
      },
    })
    await db.auditLog.create({ data: { actorId: s.id, action: 'service.create', entity: 'service', entityId: svc.id, newValue: JSON.stringify(b) } })
    return ok({ id: svc.id })
  })
}

// PATCH /api/admin/services — update { id, ...fields }
export async function PATCH(req: Request) {
  return handleError(async () => {
    const s = await getSession()
    if (!s) return unauthorized()
    const { id, ...fields } = await req.json().catch(() => ({}))
    if (!id) return fail('id مطلوب', 400)
    const existing = await db.service.findUnique({ where: { id } })
    if (!existing) return fail('غير موجود', 404)
    const data: Record<string, unknown> = {}
    for (const k of ['nameAr','nameEn','descriptionAr','descriptionEn','slug','category','imageUrl','status']) {
      if (fields[k] !== undefined) data[k] = fields[k]
    }
    if (fields.price !== undefined) data.price = new Decimal(Number(fields.price))
    if (fields.sortOrder !== undefined) data.sortOrder = Number(fields.sortOrder)
    const updated = await db.service.update({ where: { id }, data })
    await db.auditLog.create({ data: { actorId: s.id, action: 'service.edit', entity: 'service', entityId: id, oldValue: JSON.stringify(existing), newValue: JSON.stringify(data) } })
    return ok({ id: updated.id })
  })
}

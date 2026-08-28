import { db } from '@/lib/db'
import { ok, fail, handleError, unauthorized } from '@/lib/api'
import { getSession } from '@/lib/auth'
import { Decimal } from '@prisma/client/runtime/library'

export const dynamic = 'force-dynamic'

// GET /api/admin/offers
export async function GET() {
  return handleError(async () => {
    const s = await getSession()
    if (!s) return unauthorized()
    const items = await db.offer.findMany({ orderBy: { sortOrder: 'asc' }, include: { rooms: true } })
    return ok(items.map(o => ({
      id: o.id, slug: o.slug, nameAr: o.nameAr, nameEn: o.nameEn,
      descriptionAr: o.descriptionAr, descriptionEn: o.descriptionEn,
      imageUrl: o.imageUrl, startsAt: o.startsAt, endsAt: o.endsAt,
      discountType: o.discountType, discountValue: Number(o.discountValue),
      conditions: o.conditions, status: o.status, sortOrder: o.sortOrder,
      roomTypeIds: o.rooms.map(r => r.roomTypeId),
    })))
  })
}

// POST /api/admin/offers — create
export async function POST(req: Request) {
  return handleError(async () => {
    const s = await getSession()
    if (!s) return unauthorized()
    const b = await req.json().catch(() => ({}))
    const { slug, nameAr, nameEn, descriptionAr, descriptionEn, imageUrl, startsAt, endsAt, discountType = 'percentage', discountValue, conditions, status = 'published', roomTypeIds = [] } = b as Record<string, string | number | string[]>
    if (!slug || !nameAr || !nameEn || !startsAt || !endsAt || discountValue === undefined) return fail('بيانات ناقصة', 400)
    const o = await db.offer.create({
      data: {
        slug: slug as string, nameAr: nameAr as string, nameEn: nameEn as string,
        descriptionAr: (descriptionAr as string) || '', descriptionEn: (descriptionEn as string) || '',
        imageUrl: (imageUrl as string) || null,
        startsAt: new Date(startsAt as string), endsAt: new Date(endsAt as string),
        discountType: discountType as string, discountValue: new Decimal(Number(discountValue)),
        conditions: (conditions as string) || null, status: status as string,
        rooms: { create: (roomTypeIds as string[]).map((rtId: string) => ({ roomTypeId: rtId })) },
      },
    })
    await db.auditLog.create({ data: { actorId: s.id, action: 'offer.create', entity: 'offer', entityId: o.id, newValue: JSON.stringify(b) } })
    return ok({ id: o.id })
  })
}

// PATCH /api/admin/offers — update { id, ...fields }
export async function PATCH(req: Request) {
  return handleError(async () => {
    const s = await getSession()
    if (!s) return unauthorized()
    const { id, ...fields } = await req.json().catch(() => ({}))
    if (!id) return fail('id مطلوب', 400)
    const existing = await db.offer.findUnique({ where: { id } })
    if (!existing) return fail('غير موجود', 404)
    const data: Record<string, unknown> = {}
    for (const k of ['nameAr','nameEn','descriptionAr','descriptionEn','slug','imageUrl','conditions','discountType','status']) {
      if (fields[k] !== undefined) data[k] = fields[k]
    }
    if (fields.startsAt !== undefined) data.startsAt = new Date(fields.startsAt)
    if (fields.endsAt !== undefined) data.endsAt = new Date(fields.endsAt)
    if (fields.discountValue !== undefined) data.discountValue = new Decimal(Number(fields.discountValue))
    if (fields.sortOrder !== undefined) data.sortOrder = Number(fields.sortOrder)
    const updated = await db.offer.update({ where: { id }, data })
    if (Array.isArray(fields.roomTypeIds)) {
      await db.offerRoom.deleteMany({ where: { offerId: id } })
      await db.offerRoom.createMany({ data: (fields.roomTypeIds as string[]).map(rtId => ({ offerId: id, roomTypeId: rtId })) })
    }
    await db.auditLog.create({ data: { actorId: s.id, action: 'offer.edit', entity: 'offer', entityId: id, oldValue: JSON.stringify(existing), newValue: JSON.stringify(data) } })
    return ok({ id: updated.id })
  })
}

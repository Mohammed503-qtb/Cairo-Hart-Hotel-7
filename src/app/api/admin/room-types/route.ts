import { db } from '@/lib/db'
import { ok, fail, handleError, unauthorized } from '@/lib/api'
import { getSession } from '@/lib/auth'
import { Decimal } from '@prisma/client/runtime/library'

export const dynamic = 'force-dynamic'

// GET /api/admin/room-types
export async function GET() {
  return handleError(async () => {
    const s = await getSession()
    if (!s) return unauthorized()
    const items = await db.roomType.findMany({ orderBy: { sortOrder: 'asc' }, include: { rooms: true } })
    return ok(items.map(r => ({
      id: r.id, slug: r.slug, nameAr: r.nameAr, nameEn: r.nameEn,
      descriptionAr: r.descriptionAr, descriptionEn: r.descriptionEn,
      basePrice: Number(r.basePrice), currency: r.currency,
      capacity: r.capacity, beds: r.beds, size: r.size,
      amenities: JSON.parse(r.amenitiesJson || '[]'),
      imageUrl: r.imageUrl, status: r.status, sortOrder: r.sortOrder,
      roomsCount: r.rooms.length,
    })))
  })
}

// POST /api/admin/room-types — create
export async function POST(req: Request) {
  return handleError(async () => {
    const s = await getSession()
    if (!s) return unauthorized()
    const b = await req.json().catch(() => ({}))
    const { slug, nameAr, nameEn, descriptionAr, descriptionEn, basePrice, capacity, beds, size, amenities, imageUrl, status = 'published' } = b as Record<string, string | number | string[]>
    if (!slug || !nameAr || !nameEn || basePrice === undefined) return fail('بيانات ناقصة', 400)
    const rt = await db.roomType.create({
      data: {
        slug: slug as string, nameAr: nameAr as string, nameEn: nameEn as string,
        descriptionAr: (descriptionAr as string) || '', descriptionEn: (descriptionEn as string) || '',
        basePrice: new Decimal(Number(basePrice)), capacity: Number(capacity) || 2,
        beds: (beds as string) || '1 Double', size: size ? Number(size) : null,
        amenitiesJson: JSON.stringify(amenities || []),
        imageUrl: (imageUrl as string) || null, status: status as string,
      },
    })
    await db.auditLog.create({ data: { actorId: s.id, action: 'room_type.create', entity: 'room_type', entityId: rt.id, newValue: JSON.stringify(b) } })
    return ok({ id: rt.id, slug: rt.slug })
  })
}

// PATCH /api/admin/room-types — update { id, ...fields }
export async function PATCH(req: Request) {
  return handleError(async () => {
    const s = await getSession()
    if (!s) return unauthorized()
    const { id, ...fields } = await req.json().catch(() => ({}))
    if (!id) return fail('id مطلوب', 400)
    const existing = await db.roomType.findUnique({ where: { id } })
    if (!existing) return fail('غير موجود', 404)
    const data: Record<string, unknown> = {}
    for (const k of ['nameAr','nameEn','descriptionAr','descriptionEn','slug','beds','imageUrl','status']) {
      if (fields[k] !== undefined) data[k] = fields[k]
    }
    if (fields.basePrice !== undefined) data.basePrice = new Decimal(Number(fields.basePrice))
    if (fields.capacity !== undefined) data.capacity = Number(fields.capacity)
    if (fields.size !== undefined) data.size = fields.size ? Number(fields.size) : null
    if (fields.amenities !== undefined) data.amenitiesJson = JSON.stringify(fields.amenities)
    if (fields.sortOrder !== undefined) data.sortOrder = Number(fields.sortOrder)
    const updated = await db.roomType.update({ where: { id }, data })
    await db.auditLog.create({ data: { actorId: s.id, action: 'room_type.edit', entity: 'room_type', entityId: id, oldValue: JSON.stringify(existing), newValue: JSON.stringify(data) } })
    return ok({ id: updated.id })
  })
}

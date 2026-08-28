import { db } from '@/lib/db'
import { ok, handleError } from '@/lib/api'

export const dynamic = 'force-dynamic'

// GET /api/public/room-types
export async function GET() {
  return handleError(async () => {
    const types = await db.roomType.findMany({
      where: { status: 'published' },
      orderBy: { sortOrder: 'asc' },
    })
    return ok(types.map(r => ({
      id: r.id, slug: r.slug,
      nameAr: r.nameAr, nameEn: r.nameEn,
      descriptionAr: r.descriptionAr, descriptionEn: r.descriptionEn,
      basePrice: Number(r.basePrice), currency: r.currency,
      capacity: r.capacity, beds: r.beds, size: r.size,
      amenities: JSON.parse(r.amenitiesJson || '[]'),
      imageUrl: r.imageUrl, status: r.status, sortOrder: r.sortOrder,
    })))
  })
}

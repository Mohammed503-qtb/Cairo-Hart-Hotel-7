import { db } from '@/lib/db'
import { ok, handleError } from '@/lib/api'

export const dynamic = 'force-dynamic'

// GET /api/public/home — full homepage data
export async function GET() {
  return handleError(async () => {
    const [settings, sections, roomTypes, offers, services, gallery, reviews, flags] = await Promise.all([
      db.hotelSetting.findMany(),
      db.contentSection.findMany({ orderBy: { sortOrder: 'asc' } }),
      db.roomType.findMany({ where: { status: 'published' }, orderBy: { sortOrder: 'asc' } }),
      db.offer.findMany({ where: { status: 'published' }, orderBy: { sortOrder: 'asc' } }),
      db.service.findMany({ where: { status: 'published' }, orderBy: { sortOrder: 'asc' } }),
      db.galleryItem.findMany({ where: { published: true }, orderBy: { sortOrder: 'asc' } }),
      db.review.findMany({ where: { status: 'approved' }, orderBy: { createdAt: 'desc' }, take: 6, include: { guest: true } }),
      db.featureFlag.findMany(),
    ])
    const settingsMap = Object.fromEntries(settings.map(s => [s.key, s.value]))
    return ok({
      settings: settingsMap,
      sections: sections.map(s => ({ ...s, config: JSON.parse(s.configJson || '{}') })),
      roomTypes: roomTypes.map(r => ({ ...r, basePrice: Number(r.basePrice), amenities: JSON.parse(r.amenitiesJson || '[]') })),
      offers: offers.map(o => ({ ...o, discountValue: Number(o.discountValue) })),
      services: services.map(s => ({ ...s, price: Number(s.price) })),
      gallery: gallery.map(g => ({ id: g.id, url: g.url, altAr: g.altAr, altEn: g.altEn })),
      reviews: reviews.map(r => ({ id: r.id, rating: r.rating, titleAr: r.titleAr, bodyAr: r.bodyAr, guestName: r.guest?.name || 'ضيف', createdAt: r.createdAt })),
      flags: Object.fromEntries(flags.map(f => [f.key, f.enabled])),
    })
  })
}

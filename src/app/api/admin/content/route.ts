import { db } from '@/lib/db'
import { ok, fail, handleError, unauthorized } from '@/lib/api'
import { getSession } from '@/lib/auth'

export const dynamic = 'force-dynamic'

// GET /api/admin/content — all sections + faq + policies + gallery
export async function GET() {
  return handleError(async () => {
    const s = await getSession()
    if (!s) return unauthorized()
    const [sections, faqs, policies, gallery, settings] = await Promise.all([
      db.contentSection.findMany({ orderBy: { sortOrder: 'asc' } }),
      db.faq.findMany({ orderBy: { sortOrder: 'asc' } }),
      db.policy.findMany({ orderBy: { sortOrder: 'asc' } }),
      db.galleryItem.findMany({ orderBy: { sortOrder: 'asc' } }),
      db.hotelSetting.findMany(),
    ])
    return ok({
      sections: sections.map(x => ({ ...x, config: JSON.parse(x.configJson || '{}') })),
      faqs, policies, gallery,
      settings: Object.fromEntries(settings.map(s => [s.key, s.value])),
    })
  })
}

// PATCH /api/admin/content — update a section { sectionKey, titleAr, titleEn, visible, sortOrder, config }
export async function PATCH(req: Request) {
  return handleError(async () => {
    const s = await getSession()
    if (!s) return unauthorized()
    const { sectionKey, titleAr, titleEn, visible, sortOrder, config } = await req.json().catch(() => ({}))
    if (!sectionKey) return fail('sectionKey مطلوب', 400)
    const existing = await db.contentSection.findUnique({ where: { key: sectionKey } })
    if (!existing) return fail('القسم غير موجود', 404)
    const data: Record<string, unknown> = {}
    if (titleAr !== undefined) data.titleAr = titleAr
    if (titleEn !== undefined) data.titleEn = titleEn
    if (visible !== undefined) data.visible = visible
    if (sortOrder !== undefined) data.sortOrder = Number(sortOrder)
    if (config !== undefined) data.configJson = JSON.stringify(config)
    const updated = await db.contentSection.update({ where: { key: sectionKey }, data })
    await db.auditLog.create({ data: { actorId: s.id, action: 'content.edit', entity: 'content_section', entityId: sectionKey, oldValue: JSON.stringify({ ...existing, config: JSON.parse(existing.configJson || '{}') }), newValue: JSON.stringify(data) } })
    return ok({ key: updated.key })
  })
}

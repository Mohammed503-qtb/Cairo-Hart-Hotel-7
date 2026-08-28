import { db } from '@/lib/db'
import { ok, fail, handleError, unauthorized } from '@/lib/api'
import { getSession } from '@/lib/auth'

export const dynamic = 'force-dynamic'

// GET /api/admin/settings — all settings + feature flags + roles + permissions
export async function GET() {
  return handleError(async () => {
    const s = await getSession()
    if (!s) return unauthorized()
    const [settings, flags, roles, permissions, gallery, faqs, policies] = await Promise.all([
      db.hotelSetting.findMany(),
      db.featureFlag.findMany(),
      db.role.findMany({ include: { permissions: { include: { permission: true } } } }),
      db.permission.findMany(),
      db.galleryItem.findMany({ orderBy: { sortOrder: 'asc' } }),
      db.faq.findMany({ orderBy: { sortOrder: 'asc' } }),
      db.policy.findMany({ orderBy: { sortOrder: 'asc' } }),
    ])
    return ok({
      settings: Object.fromEntries(settings.map(s => [s.key, s.value])),
      flags: flags.map(f => ({ key: f.key, enabled: f.enabled, label: f.label })),
      roles: roles.map(r => ({ key: r.key, nameAr: r.nameAr, nameEn: r.nameEn, permissions: r.permissions.map(p => p.permission.key) })),
      permissions: permissions.map(p => p.key),
      gallery, faqs, policies,
    })
  })
}

// PATCH /api/admin/settings — { settings?: {key:value}, flags?: {key:bool} }
export async function PATCH(req: Request) {
  return handleError(async () => {
    const s = await getSession()
    if (!s) return unauthorized()
    const { settings, flags } = await req.json().catch(() => ({}))
    if (settings && typeof settings === 'object') {
      for (const [k, v] of Object.entries(settings as Record<string, string>)) {
        await db.hotelSetting.upsert({ where: { key: k }, update: { value: String(v) }, create: { key: k, value: String(v) } })
      }
      await db.auditLog.create({ data: { actorId: s.id, action: 'settings.update', entity: 'hotel_settings', entityId: 'settings', newValue: JSON.stringify(settings) } })
    }
    if (flags && typeof flags === 'object') {
      for (const [k, v] of Object.entries(flags as Record<string, boolean>)) {
        await db.featureFlag.upsert({ where: { key: k }, update: { enabled: !!v }, create: { key: k, enabled: !!v, label: k } })
      }
      await db.auditLog.create({ data: { actorId: s.id, action: 'feature_flag.update', entity: 'feature_flag', entityId: 'flags', newValue: JSON.stringify(flags) } })
    }
    return ok({ success: true })
  })
}

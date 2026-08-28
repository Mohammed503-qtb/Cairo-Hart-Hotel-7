import { headers } from 'next/headers'
import { supabaseAdmin } from './supabase'
import { db } from './db'

export interface SessionUser {
  id: string
  email: string
  name: string
  roles: string[]
  permissions: string[]
}

const cache = new Map<string, { user: SessionUser; exp: number }>()

export async function getSession(): Promise<SessionUser | null> {
  const h = await headers()
  const auth = h.get('authorization') || ''
  let token = ''
  if (auth.startsWith('Bearer ')) token = auth.slice(7)
  else {
    const cookie = h.get('cookie') || ''
    const m = cookie.match(/sb-token=([^;]+)/)
    if (m) token = decodeURIComponent(m[1])
  }
  if (!token || !supabaseAdmin) return null

  const now = Date.now()
  const cached = cache.get(token)
  if (cached && cached.exp > now) return cached.user

  const { data, error } = await supabaseAdmin.auth.getUser(token)
  if (error || !data.user) return null

  const user = await db.user.findUnique({
    where: { email: data.user.email || '' },
    include: { roles: { include: { role: { include: { permissions: { include: { permission: true } } } } } } },
  })
  if (!user || user.status !== 'active') return null

  const roles = user.roles.map(ur => ur.role.key)
  const permissions = Array.from(new Set(
    user.roles.flatMap(ur => ur.role.permissions.map(rp => rp.permission.key))
  ))

  const result: SessionUser = { id: user.id, email: user.email || user.phone || user.name, name: user.name, roles, permissions }
  cache.set(token, { user: result, exp: now + 60_000 })
  return result
}

export async function requireAuth(): Promise<SessionUser> {
  const s = await getSession()
  if (!s) throw new Error('UNAUTHORIZED')
  return s
}

export async function requirePermission(perm: string): Promise<SessionUser> {
  const s = await requireAuth()
  if (!s.permissions.includes(perm) && !s.roles.includes('admin')) {
    throw new Error('FORBIDDEN')
  }
  return s
}

export function hasPermission(s: SessionUser, perm: string) {
  return s.roles.includes('admin') || s.permissions.includes(perm)
}

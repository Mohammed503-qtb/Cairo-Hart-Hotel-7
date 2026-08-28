import { NextResponse } from 'next/server'
import { supabaseAdmin } from '@/lib/supabase'
import { db } from '@/lib/db'
import { ok, fail, handleError } from '@/lib/api'

export const dynamic = 'force-dynamic'

// POST /api/auth/login — { email, password }
export async function POST(req: Request) {
  return handleError(async () => {
    const { email, password } = await req.json().catch(() => ({}))
    if (!email || !password) return fail('البريد وكلمة المرور مطلوبان', 400)
    if (!supabaseAdmin) return fail('المصادقة غير مفعّلة', 500)

    const { data, error } = await supabaseAdmin.auth.signInWithPassword({ email, password })
    if (error || !data.session) return fail('بيانات الدخول غير صحيحة', 401)

    // Verify user exists in our DB and is active
    const user = await db.user.findUnique({
      where: { email },
      include: { roles: { include: { role: true } } },
    })
    if (!user || user.status !== 'active') return fail('الحساب غير مفعّل', 403)

    const res = NextResponse.json({
      token: data.session.access_token,
      user: {
        id: user.id, email: user.email, name: user.name,
        roles: user.roles.map(r => r.role.key),
        roleNames: user.roles.map(r => r.role.nameAr),
      },
    })
    res.cookies.set('sb-token', data.session.access_token, {
      httpOnly: true, secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax', path: '/', maxAge: 3600,
    })
    return res
  })
}

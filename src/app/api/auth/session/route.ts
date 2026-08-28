import { ok, handleError } from '@/lib/api'
import { getSession } from '@/lib/auth'

export const dynamic = 'force-dynamic'

// GET /api/auth/session — verify token & return current user
export async function GET() {
  return handleError(async () => {
    const s = await getSession()
    if (!s) return ok({ authenticated: false })
    return ok({ authenticated: true, user: s })
  })
}

// POST /api/auth/logout
export async function POST() {
  return handleError(async () => {
    const res = ok({ success: true })
    res.cookies.delete('sb-token')
    return res
  })
}

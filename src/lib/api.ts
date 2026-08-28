import { NextResponse } from 'next/server'
import { Decimal } from '@prisma/client/runtime/library'

export function ok(data: unknown = { success: true }) {
  return NextResponse.json(data)
}

export function fail(message: string, status = 400, code?: string) {
  return NextResponse.json({ error: message, code: code || message }, { status })
}

export function unauthorized() {
  return NextResponse.json({ error: 'غير مصرح', code: 'UNAUTHORIZED' }, { status: 401 })
}

export function forbidden() {
  return NextResponse.json({ error: 'صلاحية غير كافية', code: 'FORBIDDEN' }, { status: 403 })
}

export function notFound(msg = 'غير موجود') {
  return NextResponse.json({ error: msg, code: 'NOT_FOUND' }, { status: 404 })
}

export async function handleError(fn: () => Promise<NextResponse>) {
  try {
    return await fn()
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e)
    if (msg === 'UNAUTHORIZED') return unauthorized()
    if (msg === 'FORBIDDEN') return forbidden()
    if (msg === 'NOT_FOUND') return notFound()
    console.error('API error:', msg)
    return fail('حدث خطأ أثناء تنفيذ العملية', 500, 'INTERNAL')
  }
}

export function dec(n: number | Decimal | string): number {
  if (n instanceof Decimal) return n.toNumber()
  if (typeof n === 'string') return parseFloat(n)
  return n
}

export function genRef(prefix: string): string {
  const t = Date.now().toString(36).toUpperCase().slice(-6)
  const r = Math.random().toString(36).toUpperCase().slice(2, 6)
  return `${prefix}-${t}${r}`
}

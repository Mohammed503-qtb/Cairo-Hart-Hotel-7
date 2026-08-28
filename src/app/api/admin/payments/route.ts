import { db } from '@/lib/db'
import { ok, fail, handleError, unauthorized, genRef } from '@/lib/api'
import { getSession } from '@/lib/auth'
import { Decimal } from '@prisma/client/runtime/library'

export const dynamic = 'force-dynamic'

// GET /api/admin/payments?reservationId=
export async function GET(req: Request) {
  return handleError(async () => {
    const s = await getSession()
    if (!s) return unauthorized()
    const { searchParams } = new URL(req.url)
    const reservationId = searchParams.get('reservationId')
    const status = searchParams.get('status') || ''
    const where: Record<string, unknown> = {}
    if (reservationId) where.reservationId = reservationId
    if (status) where.status = status
    const items = await db.payment.findMany({
      where, include: { reservation: { include: { guest: true } }, recordedBy: { select: { name: true } } },
      orderBy: { createdAt: 'desc' },
    })
    return ok(items.map(p => ({
      id: p.id, reference: p.reference, reservationId: p.reservationId,
      confirmationNo: p.reservation.confirmationNo, guestName: p.reservation.guest.name,
      method: p.method, amount: Number(p.amount), currency: p.currency, status: p.status,
      externalRef: p.externalRef, notes: p.notes, createdAt: p.createdAt,
      recordedBy: p.recordedBy?.name || null,
    })))
  })
}

// POST /api/admin/payments — record a payment { reservationId, method, amount, externalRef?, proofUrl?, notes? }
export async function POST(req: Request) {
  return handleError(async () => {
    const s = await getSession()
    if (!s) return unauthorized()
    const { reservationId, method, amount, externalRef, proofUrl, notes, status = 'paid' } = await req.json().catch(() => ({}))
    if (!reservationId || !method || amount === undefined) return fail('بيانات ناقصة', 400)
    const reservation = await db.reservation.findUnique({ where: { id: reservationId } })
    if (!reservation) return fail('الحجز غير موجود', 404)

    const payment = await db.payment.create({
      data: {
        reference: genRef('PAY'),
        reservationId, method, amount: new Decimal(Number(amount)),
        currency: reservation.currency, status,
        externalRef: externalRef || null, proofUrl: proofUrl || null,
        notes: notes || null, recordedById: s.id,
      },
    })

    // Update reservation paid/remaining + payment status
    const payments = await db.payment.findMany({ where: { reservationId, status: 'paid' } })
    const totalPaid = payments.reduce((sum, p) => sum + Number(p.amount), 0)
    const total = Number(reservation.totalSnapshot)
    const remaining = Math.max(0, total - totalPaid)
    const paymentStatus = totalPaid >= total ? 'paid' : totalPaid > 0 ? 'partially_paid' : 'pending'
    await db.reservation.update({ where: { id: reservationId }, data: { paidAmount: new Decimal(totalPaid), remainingAmount: new Decimal(remaining), paymentStatus } })

    await db.auditLog.create({ data: { actorId: s.id, action: 'payment.record', entity: 'payment', entityId: payment.id, newValue: JSON.stringify({ reservationId, method, amount, status }) } })
    return ok({ id: payment.id, reference: payment.reference, totalPaid, remaining, paymentStatus })
  })
}

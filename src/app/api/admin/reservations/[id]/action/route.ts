import { db } from '@/lib/db'
import { ok, fail, handleError, unauthorized } from '@/lib/api'
import { getSession } from '@/lib/auth'
import { Decimal } from '@prisma/client/runtime/library'

export const dynamic = 'force-dynamic'

const TRANSITIONS: Record<string, string[]> = {
  draft: ['pending'],
  pending: ['awaiting_confirmation', 'rejected', 'cancelled'],
  awaiting_confirmation: ['confirmed', 'cancelled', 'rejected'],
  confirmed: ['checked_in', 'cancelled', 'no_show'],
  checked_in: ['checked_out'],
  checked_out: ['completed'],
  completed: [],
  cancelled: [],
  no_show: [],
  rejected: [],
}

const ROOM_STATUS_FOR_BOOKING: Record<string, string> = {
  confirmed: 'reserved',
  checked_in: 'occupied',
  checked_out: 'cleaning',
  cancelled: 'available',
  no_show: 'available',
}

// POST /api/admin/reservations/[id]/action — { action, reason? }
// action ∈ confirm | reject | cancel | checkin | checkout | noshow | complete
export async function POST(req: Request, { params }: { params: Promise<{ id: string }> }) {
  return handleError(async () => {
    const s = await getSession()
    if (!s) return unauthorized()
    const { id } = await params
    const { action, reason } = await req.json().catch(() => ({}))
    if (!action) return fail('الإجراء مطلوب', 400)

    const reservation = await db.reservation.findUnique({ where: { id }, include: { room: true, roomType: true } })
    if (!reservation) return fail('الحجز غير موجود', 404)

    const actionToStatus: Record<string, string> = {
      confirm: 'confirmed', reject: 'rejected', cancel: 'cancelled',
      checkin: 'checked_in', checkout: 'checked_out', noshow: 'no_show', complete: 'completed',
    }
    const newStatus = actionToStatus[action]
    if (!newStatus) return fail('إجراء غير معروف', 400)

    const allowed = TRANSITIONS[reservation.bookingStatus] || []
    if (!allowed.includes(newStatus) && reservation.bookingStatus !== newStatus) {
      return fail(`لا يمكن الانتقال من ${reservation.bookingStatus} إلى ${newStatus}`, 409)
    }

    const updated = await db.reservation.update({
      where: { id },
      data: { bookingStatus: newStatus, cancellationStatus: action === 'cancel' ? 'cancelled' : action === 'noshow' ? 'no_show' : reservation.cancellationStatus },
      include: { room: true },
    })

    // Update room status
    if (reservation.roomId && ROOM_STATUS_FOR_BOOKING[newStatus]) {
      await db.room.update({ where: { id: reservation.roomId }, data: { status: ROOM_STATUS_FOR_BOOKING[newStatus] } }).catch(() => {})
      // housekeeping task on checkout
      if (newStatus === 'checked_out') {
        await db.housekeepingTask.create({ data: { roomId: reservation.roomId, status: 'pending', priority: 'normal', notes: `تنظيف بعد مغادرة الحجز ${reservation.confirmationNo}` } }).catch(() => {})
      }
    }

    await db.auditLog.create({
      data: {
        actorId: s.id, action: `reservation.${action}`, entity: 'reservation', entityId: id,
        oldValue: reservation.bookingStatus, newValue: newStatus, reason: reason || null,
      },
    })

    // Notify guest (via contact request if phone present) — handled by admin UI separately
    return ok({ id: updated.id, bookingStatus: updated.bookingStatus, confirmationNo: updated.confirmationNo })
  })
}

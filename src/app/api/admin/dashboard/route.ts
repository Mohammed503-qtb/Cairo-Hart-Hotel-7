import { db } from '@/lib/db'
import { ok, handleError, unauthorized } from '@/lib/api'
import { getSession } from '@/lib/auth'

export const dynamic = 'force-dynamic'

// GET /api/admin/dashboard — overview stats + needs attention
export async function GET() {
  return handleError(async () => {
    const s = await getSession()
    if (!s) return unauthorized()

    const today = new Date()
    today.setHours(0, 0, 0, 0)
    const tomorrow = new Date(today)
    tomorrow.setDate(tomorrow.getDate() + 1)

    const [
      todaysCheckins, todaysCheckouts, occupiedRooms, availableRooms,
      cleaningRooms, maintenanceRooms, blockedRooms,
      pendingPayments, newBookingRequests, newContactRequests, openServiceRequests,
      totalGuests, totalReservations,
    ] = await Promise.all([
      db.reservation.count({ where: { checkIn: { gte: today, lt: tomorrow }, bookingStatus: 'confirmed' } }),
      db.reservation.count({ where: { checkOut: { gte: today, lt: tomorrow }, bookingStatus: { in: ['checked_in', 'checked_out'] } } }),
      db.room.count({ where: { status: 'occupied' } }),
      db.room.count({ where: { status: 'available' } }),
      db.room.count({ where: { status: 'cleaning' } }),
      db.room.count({ where: { status: 'maintenance' } }),
      db.room.count({ where: { status: 'blocked' } }),
      db.reservation.count({ where: { paymentStatus: { in: ['pending', 'submitted', 'under_review', 'partially_paid'] } } }),
      db.bookingRequest.count({ where: { status: 'new' } }),
      db.contactRequest.count({ where: { status: 'new' } }),
      db.serviceRequest.count({ where: { status: { in: ['new', 'assigned', 'in_progress', 'waiting'] } } }),
      db.guest.count(),
      db.reservation.count(),
    ])

    // Needs attention
    const attention: Array<{ kind: string; labelAr: string; labelEn: string; count: number; link: string }> = []
    if (newBookingRequests > 0) attention.push({ kind: 'booking_requests', labelAr: 'طلبات حجز جديدة', labelEn: 'New Booking Requests', count: newBookingRequests, link: '/admin/reservations' })
    if (pendingPayments > 0) attention.push({ kind: 'payments', labelAr: 'مدفوعات بانتظار المراجعة', labelEn: 'Payments Under Review', count: pendingPayments, link: '/admin/reservations' })
    if (maintenanceRooms > 0) attention.push({ kind: 'maintenance', labelAr: 'غرف تحت الصيانة', labelEn: 'Rooms Under Maintenance', count: maintenanceRooms, link: '/admin/rooms' })
    if (newContactRequests > 0) attention.push({ kind: 'contacts', labelAr: 'طلبات تواصل جديدة', labelEn: 'New Contact Requests', count: newContactRequests, link: '/admin/communication' })
    if (openServiceRequests > 0) attention.push({ kind: 'service_requests', labelAr: 'طلبات خدمات مفتوحة', labelEn: 'Open Service Requests', count: openServiceRequests, link: '/admin/service-requests' })

    // Revenue today (paid payments)
    const todayStart = today
    const paymentsToday = await db.payment.findMany({
      where: { status: 'paid', createdAt: { gte: todayStart } },
      select: { amount: true },
    })
    const revenueToday = paymentsToday.reduce((s, p) => s + Number(p.amount), 0)

    // Recent activity (last 8 audit logs)
    const recentActivity = await db.auditLog.findMany({
      take: 8, orderBy: { createdAt: 'desc' },
      include: { actor: { select: { name: true } } },
    })

    return ok({
      stats: {
        todaysCheckins, todaysCheckouts,
        occupiedRooms, availableRooms, cleaningRooms, maintenanceRooms, blockedRooms,
        pendingPayments, newBookingRequests, newContactRequests, openServiceRequests,
        totalGuests, totalReservations,
        revenueToday,
      },
      attention,
      recentActivity: recentActivity.map(a => ({
        id: a.id, actor: a.actor?.name || 'نظام', action: a.action,
        entity: a.entity, entityId: a.entityId, reason: a.reason, createdAt: a.createdAt,
      })),
      user: s,
    })
  })
}

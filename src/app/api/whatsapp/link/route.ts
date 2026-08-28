import { db } from '@/lib/db'
import { ok, fail, handleError } from '@/lib/api'

export const dynamic = 'force-dynamic'

// POST /api/whatsapp/link — generate a wa.me link with structured booking info
// body: { guestName, guestPhone, roomTypeNameAr?, checkIn?, checkOut?, adults?, children?, nights?, message?, bookingRef? }
export async function POST(req: Request) {
  return handleError(async () => {
    const body = await req.json().catch(() => ({}))
    const { guestName, guestPhone, roomTypeNameAr, checkIn, checkOut, adults, children, nights, message, bookingRef } = body as Record<string, string | number>

    const phoneSetting = await db.hotelSetting.findUnique({ where: { key: 'hotel.whatsapp' } })
    const hotelWhatsapp = phoneSetting?.value || '967700123456'
    const hotelName = (await db.hotelSetting.findUnique({ where: { key: 'hotel.name_ar' } }))?.value || 'فندق قلب القاهرة'

    const lines = [
      `مرحبًا ${hotelName} 👋`,
      bookingRef ? `رقم الطلب: ${bookingRef}` : '',
      `الاسم: ${guestName || '-'}`,
      `الهاتف: ${guestPhone || '-'}`,
      roomTypeNameAr ? `الغرفة: ${roomTypeNameAr}` : '',
      checkIn ? `الوصول: ${checkIn}` : '',
      checkOut ? `المغادرة: ${checkOut}` : '',
      nights ? `عدد الليالي: ${nights}` : '',
      (adults || children) ? `الضيوف: ${adults || 0} بالغ${(children as number) ? ` + ${children} طفل` : ''}` : '',
      message ? `ملاحظات: ${message}` : '',
      'أرغب في تأكيد الحجز. شكرًا.',
    ].filter(Boolean)

    const text = encodeURIComponent(lines.join('\n'))
    const num = hotelWhatsapp.replace(/[^0-9]/g, '')
    return ok({ url: `https://wa.me/${num}?text=${text}`, phone: hotelWhatsapp, text: lines.join('\n') })
  })
}

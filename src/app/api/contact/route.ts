import { db } from '@/lib/db'
import { ok, fail, handleError, genRef } from '@/lib/api'

export const dynamic = 'force-dynamic'

// POST /api/contact — guest sends a contact/whatsapp request (logged into communication center)
export async function POST(req: Request) {
  return handleError(async () => {
    const body = await req.json().catch(() => ({}))
    const { guestName, guestPhone, channel = 'whatsapp', subject, message } = body as Record<string, string>
    if (!guestName || !guestPhone || !message) return fail('الاسم والهاتف والرسالة مطلوبة', 400)

    let guest = await db.guest.findFirst({ where: { phone: guestPhone } })
    if (!guest) guest = await db.guest.create({ data: { name: guestName, phone: guestPhone } })

    const cr = await db.contactRequest.create({
      data: {
        reference: genRef('CR'),
        guestId: guest.id,
        guestName, guestPhone,
        channel, subject: subject || null,
        message, status: 'new', priority: 'normal',
      },
    })

    // Generate WhatsApp link
    const phoneSetting = await db.hotelSetting.findUnique({ where: { key: 'hotel.whatsapp' } })
    const hotelWhatsapp = (phoneSetting?.value || '967700123456').replace(/[^0-9]/g, '')
    const text = encodeURIComponent(`${subject ? subject + '\n' : ''}${message}\n\n— ${guestName} (${guestPhone})`)
    const waUrl = `https://wa.me/${hotelWhatsapp}?text=${text}`

    await db.notification.create({
      data: {
        titleAr: 'طلب تواصل جديد',
        titleEn: 'New Contact Request',
        bodyAr: `${cr.reference} من ${guestName}`,
        bodyEn: `${cr.reference} from ${guestName}`,
        link: '/admin/communication',
        category: 'contact',
      },
    }).catch(() => {})

    return ok({ reference: cr.reference, whatsappUrl: waUrl, createdAt: cr.createdAt })
  })
}

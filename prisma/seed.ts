import { db } from '@/lib/db'
import { supabaseAdmin } from '@/lib/supabase'
import bcrypt from 'bcryptjs'
import { Decimal } from '@prisma/client/runtime/library'

const HOTEL_IMAGES = [
  'https://images.unsplash.com/photo-1566073771259-6a1486048258?w=1200',
  'https://images.unsplash.com/photo-1551882547-ff5a8c1b0c1d?w=1200',
  'https://images.unsplash.com/photo-1571896349842-4e6a3a2a9a3b?w=1200',
  'https://images.unsplash.com/photo-1582719478250-1f2b4d3a7c4e?w=1200',
  'https://images.unsplash.com/photo-1618773928601-6d7a3a2a9a3b?w=1200',
]
const ROOM_STANDARD = 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=1200'
const ROOM_DELUXE = 'https://images.unsplash.com/photo-1582719478250-1f2b4d3a7c4e?w=1200'
const ROOM_SUITE = 'https://images.unsplash.com/photo-1590490364447-4a3a2a2a9a3b?w=1200'
const ROOM_FAMILY = 'https://images.unsplash.com/photo-1566665797739-1674b3a2a9a3b?w=1200'
const GALLERY = [
  'https://images.unsplash.com/photo-1564501049412-61b7c7a2a9a3b?w=1200',
  'https://images.unsplash.com/photo-1578683014347-4e2a2a2a9a3b?w=1200',
  'https://images.unsplash.com/photo-1582719508461-4f2a2a9a3b?w=1200',
  'https://images.unsplash.com/photo-1618773928601-6d7a3a2a9a3b?w=1200',
  'https://images.unsplash.com/photo-1551882547-ff5a8c1b0c1d?w=1200',
  'https://images.unsplash.com/photo-1566073771259-6a1486048258?w=1200',
]

function dec(n: number) { return new Decimal(n) }

async function main() {
  console.log('Seeding Cairo Heart Hotel...')

  // ── Roles & Permissions ──
  const perms = [
    'reservation.view','reservation.create','reservation.edit','reservation.cancel','reservation.confirm',
    'payment.view','payment.record','payment.approve','payment.refund',
    'room.view','room.edit','room.status',
    'content.view','content.edit','content.publish',
    'report.view','user.manage','system.manage','audit.view',
  ]
  for (const k of perms) {
    await db.permission.upsert({ where: { key: k }, update: {}, create: { key: k, label: k } })
  }
  const roleDefs = [
    { key: 'admin', ar: 'مدير النظام', en: 'Administrator' },
    { key: 'manager', ar: 'مدير', en: 'Manager' },
    { key: 'receptionist', ar: 'موظف استقبال', en: 'Receptionist' },
    { key: 'booking_operator', ar: 'موظف حجوزات', en: 'Booking Operator' },
    { key: 'housekeeping', ar: 'خدمة الغرف', en: 'Housekeeping' },
    { key: 'content_editor', ar: 'محرر محتوى', en: 'Content Editor' },
  ]
  for (const r of roleDefs) {
    await db.role.upsert({ where: { key: r.key }, update: { nameAr: r.ar, nameEn: r.en }, create: { key: r.key, nameAr: r.ar, nameEn: r.en } })
  }
  // Assign all permissions to admin role
  const adminRole = await db.role.findUnique({ where: { key: 'admin' } })
  const allPerms = await db.permission.findMany()
  for (const p of allPerms) {
    await db.rolePermission.upsert({ where: { roleId_permissionId: { roleId: adminRole!.id, permissionId: p.id } }, update: {}, create: { roleId: adminRole!.id, permissionId: p.id } })
  }
  // Manager gets most except user.manage, system.manage
  const managerRole = await db.role.findUnique({ where: { key: 'manager' } })
  for (const p of allPerms.filter(p => !['user.manage','system.manage'].includes(p.key))) {
    await db.rolePermission.upsert({ where: { roleId_permissionId: { roleId: managerRole!.id, permissionId: p.id } }, update: {}, create: { roleId: managerRole!.id, permissionId: p.id } })
  }

  // ── Admin User (via Supabase Auth + our users table) ──
  if (supabaseAdmin) {
    const adminEmail = 'admin@cairoheart.ye'
    const { data: existing } = await supabaseAdmin.auth.admin.getUserById('seeded-admin').catch(() => ({ data: { user: null } }))
    let adminAuthId: string | undefined
    const { data: listUsers } = await supabaseAdmin.auth.admin.listUsers()
    const found = listUsers?.users?.find(u => u.email === adminEmail)
    if (found) {
      adminAuthId = found.id
    } else {
      const { data, error } = await supabaseAdmin.auth.admin.createUser({
        email: adminEmail,
        password: 'Admin@12345',
        email_confirm: true,
        user_metadata: { name: 'Hotel Administrator' },
      })
      if (!error && data.user) adminAuthId = data.user.id
    }
    const passHash = bcrypt.hashSync('Admin@12345', 10)
    await db.user.upsert({
      where: { email: adminEmail },
      update: { name: 'Hotel Administrator', phone: '+967700000000', passwordHash: passHash, status: 'active' },
      create: { email: adminEmail, name: 'Hotel Administrator', phone: '+967700000000', passwordHash: passHash, status: 'active' },
    })
    const adminUser = await db.user.findUnique({ where: { email: adminEmail } })
    if (adminUser && adminRole) {
      await db.userRole.upsert({ where: { userId_roleId: { userId: adminUser.id, roleId: adminRole.id } }, update: {}, create: { userId: adminUser.id, roleId: adminRole.id } })
    }
    console.log('Admin user ready:', adminEmail, '/ Admin@12345')
  }

  // ── Hotel Settings ──
  const settings: Record<string,string> = {
    'hotel.name_ar': 'فندق قلب القاهرة',
    'hotel.name_en': 'Cairo Heart Hotel',
    'hotel.description_ar': 'فندق راقٍ في قلب عدن يجمع بين الفخامة والضيافة العربية الأصيلة.',
    'hotel.description_en': 'A refined hotel in the heart of Aden blending luxury with authentic Arabian hospitality.',
    'hotel.phone': '+967700123456',
    'hotel.whatsapp': '967700123456',
    'hotel.email': 'info@cairoheart.ye',
    'hotel.address_ar': 'عدن - شارع الملكة أروى',
    'hotel.address_en': 'Aden - Queen Arwa Street',
    'hotel.maps_url': 'https://maps.google.com/?q=Aden',
    'hotel.checkin_time': '14:00',
    'hotel.checkout_time': '12:00',
    'booking.min_nights': '1',
    'booking.max_nights': '30',
    'cancellation.policy_ar': 'الإلغاء مجاني حتى 24 ساعة قبل موعد الوصول. بعدها يُخصم ليلة واحدة.',
    'cancellation.policy_en': 'Free cancellation up to 24 hours before arrival. After that, one night is charged.',
    'localization.currency': 'YER',
    'localization.currency_symbol_ar': 'ر.ي',
    'localization.currency_symbol_en': 'YER',
    'localization.language': 'ar',
  }
  for (const [k,v] of Object.entries(settings)) {
    await db.hotelSetting.upsert({ where: { key: k }, update: { value: v }, create: { key: k, value: v } })
  }

  // ── Feature Flags ──
  const flags = [
    { key: 'online_payment', label: 'Online Payment', enabled: false },
    { key: 'reviews', label: 'Reviews', enabled: true },
    { key: 'offers', label: 'Offers', enabled: true },
    { key: 'service_requests', label: 'Service Requests', enabled: true },
    { key: 'guest_accounts', label: 'Guest Accounts', enabled: true },
    { key: 'gallery', label: 'Gallery', enabled: true },
  ]
  for (const f of flags) {
    await db.featureFlag.upsert({ where: { key: f.key }, update: { label: f.label, enabled: f.enabled }, create: f })
  }

  // ── Content Sections (homepage) ──
  const sections = [
    { key:'hero', ar:'الواجهة', en:'Hero', order:1, config:JSON.stringify({ title_ar:'فندق قلب القاهرة', title_en:'Cairo Heart Hotel', subtitle_ar:'تجربة إقامة استثنائية في قلب عدن', subtitle_en:'An exceptional stay in the heart of Aden', cta_ar:'احجز الآن', cta_en:'Book Now', image: HOTEL_IMAGES[0] }) },
    { key:'quick_booking', ar:'حجز سريع', en:'Quick Booking', order:2, config:JSON.stringify({ visible:true }) },
    { key:'featured_rooms', ar:'غرف مميزة', en:'Featured Rooms', order:3, config:JSON.stringify({ title_ar:'غرفنا', title_en:'Our Rooms' }) },
    { key:'why_hotel', ar:'لماذا نحن', en:'Why Hotel', order:4, config:JSON.stringify({ title_ar:'لماذا فندق قلب القاهرة؟', title_en:'Why Cairo Heart Hotel?', features:[{ar:'موقع متميز في قلب المدينة',en:'Prime city-center location'},{ar:'غرف فاخرة ومجهزة',en:'Luxury equipped rooms'},{ar:'خدمة 24 ساعة',en:'24-hour service'},{ar:'أسعار تنافسية',en:'Competitive prices'}] }) },
    { key:'offers', ar:'عروض', en:'Offers', order:5, config:JSON.stringify({ title_ar:'عروض خاصة', title_en:'Special Offers' }) },
    { key:'services', ar:'خدمات', en:'Services', order:6, config:JSON.stringify({ title_ar:'خدماتنا', title_en:'Our Services' }) },
    { key:'gallery', ar:'معرض الصور', en:'Gallery', order:7, config:JSON.stringify({ title_ar:'معرض الصور', title_en:'Gallery' }) },
    { key:'location', ar:'الموقع', en:'Location', order:8, config:JSON.stringify({ title_ar:'موقعنا', title_en:'Our Location' }) },
    { key:'reviews', ar:'التقييمات', en:'Reviews', order:9, config:JSON.stringify({ title_ar:'آراء ضيوفنا', title_en:'Guest Reviews' }) },
    { key:'contact', ar:'تواصل', en:'Contact', order:10, config:JSON.stringify({ title_ar:'تواصل معنا', title_en:'Contact Us' }) },
  ]
  for (const s of sections) {
    await db.contentSection.upsert({
      where: { key: s.key },
      update: { titleAr: s.ar, titleEn: s.en, sortOrder: s.order, configJson: s.config },
      create: { key: s.key, titleAr: s.ar, titleEn: s.en, sortOrder: s.order, configJson: s.config, visible: true },
    })
  }

  // ── Room Types ──
  const roomTypes = [
    { slug:'standard', ar:'غرفة قياسية', en:'Standard Room', descAr:'غرفة مريحة بتصميم أنيق تتسع لشخصين، مع جميع وسائل الراحة الأساسية.', descEn:'A comfortable elegantly-designed room for two, with all essential amenities.', price:35, capacity:2, beds:'1 Double', size:22, amenities:['wifi','ac','tv','minibar','breakfast'], image: ROOM_STANDARD },
    { slug:'deluxe', ar:'غرفة ديلوكس', en:'Deluxe Room', descAr:'غرفة أوسع مع جلسة إضافية وإطلالة على المدينة وخدمات راقية.', descEn:'A larger room with a seating area, city view, and premium amenities.', price:55, capacity:2, beds:'1 King', size:30, amenities:['wifi','ac','tv','minibar','breakfast','view','safe'], image: ROOM_DELUXE },
    { slug:'suite', ar:'جناح فاخر', en:'Luxury Suite', descAr:'جناح فسيح بغرفة نوم وصالة خاصة، مثالي للإقامات الفاخرة.', descEn:'A spacious suite with a bedroom and private living area, perfect for luxury stays.', price:95, capacity:3, beds:'1 King + 1 Sofa', size:45, amenities:['wifi','ac','tv','minibar','breakfast','view','safe','lounge','bathtub'], image: ROOM_SUITE },
    { slug:'family', ar:'غرفة عائلية', en:'Family Room', descAr:'غرفة واسعة تتسع للعائلة بأسرتين كبيرتين ومرافق متكاملة.', descEn:'A spacious room for families with two large beds and full facilities.', price:75, capacity:4, beds:'2 Double', size:38, amenities:['wifi','ac','tv','minibar','breakfast','safe','crib'], image: ROOM_FAMILY },
  ]
  for (const rt of roomTypes) {
    await db.roomType.upsert({
      where: { slug: rt.slug },
      update: { nameAr: rt.ar, nameEn: rt.en, descriptionAr: rt.descAr, descriptionEn: rt.descEn, basePrice: dec(rt.price), capacity: rt.capacity, beds: rt.beds, size: rt.size, amenitiesJson: JSON.stringify(rt.amenities), imageUrl: rt.image, status: 'published', sortOrder: roomTypes.indexOf(rt) },
      create: { slug: rt.slug, nameAr: rt.ar, nameEn: rt.en, descriptionAr: rt.descAr, descriptionEn: rt.descEn, basePrice: dec(rt.price), capacity: rt.capacity, beds: rt.beds, size: rt.size, amenitiesJson: JSON.stringify(rt.amenities), imageUrl: rt.image, status: 'published', sortOrder: roomTypes.indexOf(rt) },
    })
  }

  // ── Physical Rooms ──
  const roomAssignments = [
    { type:'standard', numbers:['101','102','103','104','201','202'] },
    { type:'deluxe', numbers:['203','204','205','301','302','303'] },
    { type:'suite', numbers:['304','401'] },
    { type:'family', numbers:['402','403'] },
  ]
  for (const a of roomAssignments) {
    const rt = await db.roomType.findUnique({ where: { slug: a.type } })
    if (!rt) continue
    for (let i=0;i<a.numbers.length;i++) {
      const num = a.numbers[i]
      await db.room.upsert({
        where: { number: num },
        update: { roomTypeId: rt.id, floor: parseInt(num[0]), status: 'available' },
        create: { number: num, roomTypeId: rt.id, floor: parseInt(num[0]), status: 'available' },
      })
    }
  }

  // ── Services ──
  const services = [
    { slug:'room-service', ar:'خدمة الغرفة', en:'Room Service', cat:'food', price:0, img:'https://images.unsplash.com/photo-1582719478250-1f2b4d3a7c4e?w=800' },
    { slug:'breakfast', ar:'فطور', en:'Breakfast', cat:'food', price:5, img:'https://images.unsplash.com/photo-1535535112855-6e7e3a2a9a3b?w=800' },
    { slug:'laundry', ar:'مغسلة ملابس', en:'Laundry', cat:'laundry', price:3, img:'https://images.unsplash.com/photo-1545174647-4b4c2a2a9a3b?w=800' },
    { slug:'airport-transfer', ar:'نقل المطار', en:'Airport Transfer', cat:'transport', price:15, img:'https://images.unsplash.com/photo-1545174647-4b4c2a2a9a3b?w=800' },
    { slug:'cleaning', ar:'تنظيف الغرفة', en:'Room Cleaning', cat:'cleaning', price:0, img:'https://images.unsplash.com/photo-1582719478250-1f2b4d3a7c4e?w=800' },
    { slug:'maintenance', ar:'صيانة', en:'Maintenance', cat:'maintenance', price:0, img:'https://images.unsplash.com/photo-1582719478250-1f2b4d3a7c4e?w=800' },
  ]
  for (let i=0;i<services.length;i++) {
    const s = services[i]
    await db.service.upsert({
      where: { slug: s.slug },
      update: { nameAr: s.ar, nameEn: s.en, category: s.cat, price: dec(s.price), imageUrl: s.img, status: 'published', sortOrder: i },
      create: { slug: s.slug, nameAr: s.ar, nameEn: s.en, category: s.cat, price: dec(s.price), imageUrl: s.img, status: 'published', sortOrder: i },
    })
  }

  // ── Offers ──
  const offers = [
    { slug:'weekend-special', ar:'عرض نهاية الأسبوع', en:'Weekend Special', descAr:'خصم 15% على جميع الغرف للإقامات من الخميس إلى السبت.', descEn:'15% off all rooms for Thursday-Saturday stays.', discType:'percentage', discVal:15, days:30, img:'https://images.unsplash.com/photo-1551882547-ff5a8c1b0c1d?w=800' },
    { slug:'weekly-stay', ar:'إقامة أسبوعية', en:'Weekly Stay', descAr:'خصم 25% عند الحجز لـ 7 ليالٍ أو أكثر.', descEn:'25% off when booking 7 nights or more.', discType:'percentage', discVal:25, days:60, img:'https://images.unsplash.com/photo-1566073771259-6a1486048258?w=800' },
  ]
  for (const o of offers) {
    const now = new Date()
    const end = new Date(); end.setDate(now.getDate() + o.days)
    await db.offer.upsert({
      where: { slug: o.slug },
      update: { nameAr: o.ar, nameEn: o.en, descriptionAr: o.descAr, descriptionEn: o.descEn, imageUrl: o.img, startsAt: now, endsAt: end, discountType: o.discType, discountValue: dec(o.discVal), status: 'published' },
      create: { slug: o.slug, nameAr: o.ar, nameEn: o.en, descriptionAr: o.descAr, descriptionEn: o.descEn, imageUrl: o.img, startsAt: now, endsAt: end, discountType: o.discType, discountValue: dec(o.discVal), status: 'published' },
    })
    const offer = await db.offer.findUnique({ where: { slug: o.slug } })
    const allTypes = await db.roomType.findMany()
    for (const rt of allTypes) {
      await db.offerRoom.upsert({ where: { offerId_roomTypeId: { offerId: offer!.id, roomTypeId: rt.id } }, update: {}, create: { offerId: offer!.id, roomTypeId: rt.id } })
    }
  }

  // ── Gallery ──
  for (let i=0;i<GALLERY.length;i++) {
    await db.galleryItem.create({ data: { url: GALLERY[i], altAr: `صورة ${i+1}`, altEn: `Image ${i+1}`, sortOrder: i, published: true } }).catch(()=>{})
  }

  // ── FAQ ──
  const faqs = [
    { q:'ما مواعيد تسجيل الدخول والمغادرة؟', a:'تسجيل الدخول من الساعة 2 ظهرًا والمغادرة حتى الساعة 12 ظهرًا.' },
    { q:'هل الفطور مشمول؟', a:'نعم، الفطور مشمول في جميع أنواع الغرف.' },
    { q:'هل تتوفر خدمة الواي فاي المجاني؟', a:'نعم، واي فاي مجاني عالي السرعة في جميع أنحاء الفندق.' },
    { q:'هل يمكن إلغاء الحجز؟', a:'نعم، الإلغاء مجاني حتى 24 ساعة قبل موعد الوصول.' },
    { q:'هل تقبلون الحيوانات الأليفة؟', a:'نعتذر، لا نقبل الحيوانات الأليفة حاليًا.' },
  ]
  for (let i=0;i<faqs.length;i++) {
    await db.faq.create({ data: { questionAr: faqs[i].q, questionEn: faqs[i].q, answerAr: faqs[i].a, answerEn: faqs[i].a, sortOrder: i, published: true } }).catch(()=>{})
  }

  // ── Policies ──
  const policies = [
    { key:'booking', ar:'الحجز', en:'Booking', bodyAr:'يتطلب الحجز تأكيدًا من الفندق. سيتم التواصل معك عبر WhatsApp لتأكيد الحجز.', bodyEn:'Booking requires hotel confirmation. You will be contacted via WhatsApp to confirm.' },
    { key:'cancellation', ar:'الإلغاء', en:'Cancellation', bodyAr:'الإلغاء مجاني حتى 24 ساعة قبل الوصول. بعدها يُخصم ليلة واحدة.', bodyEn:'Free cancellation up to 24 hours before arrival. One night is charged after.' },
    { key:'payment', ar:'الدفع', en:'Payment', bodyAr:'يقبل الفندق الدفع نقدًا أو التحويل البنكي عند الوصول. الدفع الإلكتروني قيد التفعيل.', bodyEn:'Hotel accepts cash or bank transfer on arrival. Online payment coming soon.' },
    { key:'checkin', ar:'تسجيل الدخول', en:'Check-in', bodyAr:'من الساعة 2:00 ظهرًا. يتطلب إثبات هوية.', bodyEn:'From 2:00 PM. Requires ID verification.' },
    { key:'checkout', ar:'المغادرة', en:'Check-out', bodyAr:'حتى الساعة 12:00 ظهرًا. يمكن طلب تأخير المغادرة حسب التوفر.', bodyEn:'Until 12:00 PM. Late checkout available on request, subject to availability.' },
    { key:'children', ar:'الأطفال', en:'Children', bodyAr:'الأطفال تحت 6 سنوات إقامة مجانية. سرير أطفال متاح عند الطلب.', bodyEn:'Children under 6 stay free. Crib available on request.' },
  ]
  for (let i=0;i<policies.length;i++) {
    const p = policies[i]
    await db.policy.upsert({
      where: { key: p.key },
      update: { titleAr: p.ar, titleEn: p.en, bodyAr: p.bodyAr, bodyEn: p.bodyEn, published: true, sortOrder: i },
      create: { key: p.key, titleAr: p.ar, titleEn: p.en, bodyAr: p.bodyAr, bodyEn: p.bodyEn, published: true, sortOrder: i },
    })
  }

  console.log('Seed complete!')
  console.log('Admin login: admin@cairoheart.ye / Admin@12345')
}

main().catch(e => { console.error(e); process.exit(1) })

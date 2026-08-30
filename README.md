<div align="right" dir="rtl">

# فندق لوميير جراند — Lumière Grand Hotel

### منصة فندقية متكاملة متعددة المنصات (Flutter — Web · Android · iOS · macOS · Windows · Linux)

[![CI](https://github.com/Mohammed503-qtb/Cairo-Hart-Hotel-7/actions/workflows/ci.yml/badge.svg)](https://github.com/Mohammed503-qtb/Cairo-Hart-Hotel-7/actions/workflows/ci.yml)
[![Release](https://github.com/Mohammed503-qtb/Cairo-Hart-Hotel-7/actions/workflows/release.yml/badge.svg)](https://github.com/Mohammed503-qtb/Cairo-Hart-Hotel-7/releases)
[![Deploy Web](https://github.com/Mohammed503-qtb/Cairo-Hart-Hotel-7/actions/workflows/deploy-web.yml/badge.svg)](https://Mohammed503-qtb.github.io/Cairo-Hart-Hotel-7/)
[![Flutter](https://img.shields.io/badge/Flutter-3.47.2-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platforms](https://img.shields.io/badge/Platforms-Web%20·%20Android%20·%20iOS%20·%20Desktop-2E7D32)](https://flutter.dev)
[![License](https://img.shields.io/github/license/Mohammed503-qtb/Cairo-Hart-Hotel-7)](LICENSE)

</div>

---

> **منصة عمليات فندقية جاهزة للإنتاج التجاري** — موقع حجز عام + تطبيق نزيل + استقبال (PMS) +
> إدارة، مبنية بقاعدة شفرة واحدة عبر Flutter ومُحسّنة للعربية (RTL) والإنجليزية.

## ✨ المزايا

| المجال | الوصف |
|---|---|
| 🌐 **موقع الحجز العام** | الرئيسية + الغرف + تفاصيل الغرفة + المعرض + التواصل + تدفق حجز من 5 خطوات + تأكيد عبر WhatsApp |
| 📱 **تطبيق النزيل** | تفعيل برمز 6 أرقام، الإقامة الحالية، رمز الدخول، كتالوج الخدمات، تتبع الطلبات، محادثة الاستقبال، الفاتورة، تمديد/تغيير غرفة، المغادرة، الإشعارات |
| 🏨 **الاستقبال (PMS)** | لوحة عمليات بمؤشرات حية، القادمون/المغادرون/النزلاء/الحجوزات، لوحة الغرف بحالات ملوّنة، مركز الطلبات (Kanban)، تدفق تسجيل الدخول الكامل، المغادرة مع تسوية الرصيد |
| ⚙️ **الإدارة** | لوحة مؤشرات، أنواع الغرف، كتالوج الخدمات، المستخدمون، سجل التدقيق |
| 🔐 **نموذج النطاق** | فصل الحجز (Reservation) عن الإقامة (Stay)، رمز دخول مرتبط بالإقامة، فوترة بنمط السجل (Ledger)، تحويلات الغرف مؤرشفة |
| 🌍 **متعدد اللغات/الاتجاه** | عربي (RTL) + إنجليزية (LTR)، تبديل لحظي + ثيم ليلي/نهاري |

## 🚀 الإطلاق السريع (محلياً)

```bash
flutter pub get
flutter run -d chrome          # ويب
flutter run -d <device-id>     # جهاز حقيقي/محاكي
```

### بنايات الإنتاج

```bash
# ويب (ساكنة — يُرفع لأي CDN/Static host)
flutter build web --release

# أندرويد — APK + App Bundle
flutter build apk --release
flutter build appbundle --release

# iOS (يتطلب macOS + Xcode + حساب مطوّر)
flutter build ipa --release

# سطح المكتب
flutter build linux --release    # Linux
flutter build macos --release     # macOS
flutter build windows --release   # Windows
```

## 📦 الإصدارات (GitHub Releases)

كل وسم بصيغة `v*` يُطلق تلقائياً سيرفر [release.yml](.github/workflows/release.yml) الذي يبني:

- **Web** — أرشيف مضغوط جاهز للنشر + نشر تلقائي على GitHub Pages
- **Android APK** — حزمة قابلة للتثبيت مباشرة
- **Android AAB** — حزمة Google Play
- **iOS IPA** — يُبنى على macOS runner (يتطلب توقيع عبر CI secrets للنشر لـ TestFlight/App Store)
- **SHA-256 checksums** لكل أصول الإصدار
- **ملاحظات الإصدار** تلقائية من CHANGELOG

راجع [الإصدارات](https://github.com/Mohammed503-qtb/Cairo-Hart-Hotel-7/releases).

## 🏗️ معمارية المشروع

```
lib/
├── main.dart                  # نقطة الدخول + MaterialApp.router
├── core/
│   ├── app_state.dart         # حالة عامة: جلسة + ثيم + لغة
│   ├── constants.dart         # تعدادات النطاق + امتداداتها (RTL labels)
│   ├── theme.dart             # نظام تصميم موحّد (فاتح/داكن)
│   ├── router.dart            # go_router + حماية الأدوار
│   └── utils/                 # تنسيق العملة/التاريخ + استجابة الشاشات
├── data/
│   ├── models.dart            # 23 نموذج نطاقي
│   ├── seed_data.dart         # بيانات الفندق الأولية
│   └── store.dart             # مصدر الحقيقة الوحيد + كل قواعد العمل
├── features/
│   ├── shell/                 # شاشة اختيار التجربة
│   ├── website/               # الموقع العام + تدفق الحجز
│   ├── guest/                 # تطبيق النزيل
│   ├── reception/             # الاستقبال/PMS
│   └── admin/                 # الإدارة
├── l10n/                      # عربي + إنجليزي + RTL
└── shared/widgets/            # مكوّنات مشتركة
```

## 🎯 القصة الكاملة (Workflow الكنوني)

> نزيل يكتشف الفندق على الموقع → يبحث عن التوفر → يحجز → يتأكد عبر WhatsApp →
> يصل → الاستقبال يتحقق منه → يسجّل الدخول ويُسند الغرفة → تُنشأ الإقامة ويُولّد رمز الدخول →
> النزيل يفعّل التطبيق بالرمز → يطلب الخدمات → الاستقبال يعالجها → تُسجّل الرسوم →
> النزيل يطلب المغادرة → الاستقبال يُسوّي الرصيد → يُغلق الإقامة → الغرفة تدخل دورة التنظيف →
> تعود متاحة. كل عملية حساسة مؤرشفة.

## 🔑 التوقيع للإنتاج التجاري

الإطلاق التجاري على متاجر التطبيقات يتطلب مفاتيح توقيع. أضفها كـ [Encrypted Secrets](https://docs.github.com/actions/security-guides/encrypted-secrets) في المستودع:

| Secret | الغرض |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | مخزن مفاتيح أندرويد (base64) |
| `ANDROID_KEY_ALIAS` | اسم المفتاح |
| `ANDROID_KEY_PASSWORD` | كلمة سر المفتاح |
| `ANDROID_STORE_PASSWORD` | كلمة سر المخزن |
| `IOS_P12_BASE64` / `IOS_P12_PASSWORD` | شهادة توقيع iOS |
| `IOS_PROVISIONING_PROFILE_BASE64` | ملف provisioning |
| `SUPABASE_URL` / `SUPABASE_ANON_KEY` | (اختياري) ربط خلفية |

## 📜 الترخيص

MIT — راجع [LICENSE](LICENSE).

## 🗂️ المحتوى الأصلي للمستودع

المحتوى الأصلي لهذا المستودع (قبل هذا المشروع) محفوظ في فرع
[`archived-original`](https://github.com/Mohammed503-qtb/Cairo-Hart-Hotel-7/tree/archived-original)
لأغراض التاريخ.

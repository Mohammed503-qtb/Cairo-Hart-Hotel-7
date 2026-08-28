# PLAN.md

# فندق قلب القاهرة — المنصة الرقمية التشغيلية المتكاملة
## Cairo Heart Hotel — Digital Operations Platform

> **وثيقة تأسيسية إلزامية للمشروع**
>
> هذه الوثيقة ليست قائمة شاشات فقط، وليست وصفًا لتطبيق حجز فندق.
> هي المرجع الأعلى لفهم المؤسسة، ونموذج عملها، وقيمة الخدمة، ورحلة العميل،
> ورحلة الموظف، والعلاقة بين المستخدم وWhatsApp ولوحة الإدارة والـBackend.
>
> **قاعدة المشروع العليا:**
>
> **يجب فهم الغاية والعمل والخدمة والمنطق والتدفق قبل كتابة الكود.**
>
> لا يعتبر تنفيذ الشاشة نجاحًا بحد ذاته. النجاح هو أن يعمل النظام كمنظومة فندقية حقيقية،
> بسيطة للضيف، واضحة للموظف، ومسيطرًا عليها بالكامل من الإدارة.

---

# 0. PROJECT MISSION

## 0.1 الغاية

الهدف من المنصة هو إنشاء واجهة رقمية موحدة لفندق قلب القاهرة في عدن تمكن العميل من:

- اكتشاف الفندق.
- معرفة الغرف والخدمات.
- الاستعلام بسرعة.
- إرسال طلب حجز.
- تأكيد الحجز.
- التواصل مع الفندق.
- متابعة الحجز.
- طلب الخدمات.
- الوصول إلى الدعم بسهولة.

وفي الوقت نفسه تمنح الفندق نظامًا مركزيًا يستطيع من خلاله:

- استقبال الطلبات.
- إدارة الحجوزات.
- إدارة الغرف.
- إدارة الأسعار.
- إدارة التوافر.
- إدارة الضيوف.
- إدارة الطلبات والخدمات.
- إدارة المحتوى.
- إدارة العروض.
- إدارة التواصل.
- متابعة المدفوعات.
- تشغيل التقارير.
- مراقبة نشاط الموظفين.
- التحكم الكامل في المحتوى والإعدادات.

## 0.2 المشكلة التي يحلها المشروع

المشروع لا يحل مشكلة "عدم وجود تطبيق" فقط.

المشكلة الحقيقية هي وجود فجوة بين:

```text
العميل
    ↓
الاستفسار
    ↓
التواصل
    ↓
التوفر
    ↓
السعر
    ↓
الحجز
    ↓
التأكيد
    ↓
الوصول
    ↓
الخدمة
    ↓
المغادرة
```

وبين:

```text
الاستقبال
الإدارة
الحجوزات
المدفوعات
الغرف
الخدمات
المحتوى
التقارير
```

المنصة يجب أن تغلق هذه الفجوة.

## 0.3 القيمة الأساسية

القيمة للضيف:

> أقل عدد ممكن من الخطوات للوصول إلى الخدمة الصحيحة.

القيمة للفندق:

> أعلى وضوح وسيطرة على الطلبات والحجوزات والتشغيل بأقل فوضى ممكنة.

القيمة للموظف:

> معرفة ما يجب فعله الآن، ومن المسؤول عنه، وما حالته.

القيمة للإدارة:

> رؤية الحقيقة التشغيلية كاملة من مكان واحد.

---

# 1. PRINCIPLES — مبادئ غير قابلة للتفاوض

## MUST

1. فهم نموذج العمل قبل التنفيذ.
2. تصميم رحلة المستخدم قبل تصميم الشاشات.
3. تصميم رحلة الإدارة بالتوازي مع رحلة المستخدم.
4. تقليل عدد الخطوات الظاهرة للعميل.
5. استخدام WhatsApp كقناة أساسية عند الحاجة للتواصل والتأكيد.
6. جعل لوحة الإدارة مركز التحكم الفعلي.
7. فصل واجهة العميل عن منطق الأعمال.
8. جعل الـBackend مصدر الحقيقة.
9. منع تضارب الحجوزات.
10. تسجيل العمليات الحساسة.
11. عدم حذف السجلات التشغيلية المهمة بلا أثر.
12. جعل المحتوى قابلًا للتعديل من الإدارة.
13. جعل وسائل التواصل قابلة للتعديل من الإدارة.
14. جعل حالات الطلبات واضحة.
15. إظهار الحالات الحقيقية للموظف والإدارة.
16. بناء الصلاحيات على الأدوار.
17. دعم العربية وRTL من البداية.
18. دعم تجربة ويب مخصصة للإدارة.
19. دعم تجربة هاتف بسيطة للضيف.
20. الاختبار على تدفقات كاملة وليس على الشاشات فقط.

## MUST NOT

1. بناء تطبيق شكلي منفصل عن التشغيل الفعلي.
2. إجبار المستخدم على المرور بخطوات لا يحتاجها.
3. جعل WhatsApp مجرد زر اتصال مع تجاهل دوره التشغيلي.
4. وضع قواعد الحجز والتسعير الحساسة داخل Flutter فقط.
5. بناء Dashboard للعرض فقط بلا تحكم.
6. دفن الإعدادات المهمة داخل الكود.
7. جعل تعديل المحتوى يتطلب إصدارًا جديدًا من التطبيق.
8. خلط صلاحيات الموظفين.
9. بناء واجهة واحدة لكل المنصات بالقوة.
10. حذف حجز تاريخي بدل تغيير حالته.
11. إنشاء منطق مختلف لنفس البيانات في أكثر من مكان.
12. إنشاء شاشات بدون Purpose وBusiness Rules واضحة.
13. التعامل مع "الدفع" كأنه حدث UI فقط.
14. اعتبار نجاح API مساويًا لنجاح العملية التجارية.
15. افتراض أن كل عميل يريد إنشاء حساب قبل الاستفسار.
16. جعل التسجيل الإجباري حاجزًا أمام الحجز أو التواصل ما لم يكن ضروريًا.
17. بناء عملية حجز طويلة لمجرد اكتمال البيانات داخليًا.

---

# 2. DOMAIN UNDERSTANDING — فهم العمل قبل البناء

## 2.1 يجب على الذكاء الاصطناعي دراسة هذه الطبقة أولًا

قبل كتابة أي Feature يجب أن يستطيع النموذج الإجابة عن:

- ما خدمة الفندق؟
- من هو العميل؟
- ما الذي يريد العميل إنجازه؟
- ما الذي يمنع العميل من إكماله؟
- ما الذي يتم عبر الهاتف عادة؟
- ما الذي يمكن تحويله إلى WhatsApp؟
- ما الذي يمكن أتمتته؟
- ما الذي يحتاج موافقة موظف؟
- من يملك قرار قبول الحجز؟
- من يغيّر السعر؟
- من يغيّر التوفر؟
- من يؤكد الدفع؟
- ما الذي يحتاج أثرًا تدقيقيًا؟
- ما الذي يجب أن يبقى يدويًا؟
- ما الذي يمكن أن يحدث تلقائيًا؟

## 2.2 قاعدة التصميم

لا نبدأ من:

```text
Screen → Button → API
```

بل:

```text
Business Goal
→ User Need
→ Business Rule
→ Workflow
→ Data
→ Permissions
→ UX
→ API
→ Screen
→ Implementation
```

## 2.3 اختبار الفهم

قبل تنفيذ أي Feature يجب إنشاء وصف داخلي لها يتضمن:

```text
Purpose
Actors
Trigger
Preconditions
Main Flow
Alternative Flow
Business Rules
Data
Permissions
Notifications
Audit
Failure Cases
Success Criteria
```

إذا لم يستطع النموذج تحديد هذه العناصر، فلا يبدأ البرمجة.

---

# 3. PRODUCT DEFINITION

## 3.1 ماهي المنصة؟

المنصة تتكون من أربع طبقات استخدام واضحة:

### Guest Experience

تجربة العميل.

### Communication Layer

WhatsApp + اتصال + إشعارات + قنوات الدعم.

### Hotel Operations

الاستقبال والموظفون والإدارة.

### Platform Core

Backend + Database + Business Logic + Audit + Security.

## 3.2 ليست المنصة

ليست:

- متجرًا إلكترونيًا.
- تطبيقًا للحجز فقط.
- نظام CMS فقط.
- Dashboard للرسوم البيانية فقط.
- بديلًا كاملًا للموظف.
- واجهة مبنية حول تعقيد الـBackend.

---

# 4. ACTORS — المستخدمون والأدوار

## 4.1 Guest

الضيف.

يستطيع:

- مشاهدة الفندق.
- مشاهدة الغرف.
- اختيار التاريخ.
- معرفة الأسعار المتاحة.
- طلب الحجز.
- تأكيد الحجز.
- فتح WhatsApp.
- متابعة طلبه.
- تعديل الحجز وفق السياسة.
- طلب خدمة.
- مشاهدة حالة الطلب.
- تقييم الإقامة.

## 4.2 Receptionist

موظف الاستقبال.

يستطيع وفق صلاحياته:

- مشاهدة الحجوزات.
- إنشاء حجز نيابة عن العميل.
- تعديل الحجز.
- تأكيد الحضور.
- Check-in.
- Check-out.
- تسجيل المدفوعات المسموح بها.
- متابعة طلبات الخدمة.
- التواصل مع العميل.

## 4.3 Booking Operator

موظف الحجوزات.

- استقبال الطلبات.
- مراجعة التوفر.
- إرسال عروض أو بدائل.
- تأكيد الحجز.
- متابعة WhatsApp.
- تعديل حالة الطلب.
- توثيق التواصل.

## 4.4 Housekeeping

- مشاهدة الغرف المطلوبة.
- تغيير حالة التنظيف.
- تسجيل إنجاز المهام.
- الإبلاغ عن مشاكل الغرف.

## 4.5 Manager

- مشاهدة التشغيل.
- إدارة الحجوزات.
- إدارة الأسعار وفق الصلاحية.
- إدارة العروض.
- إدارة الخدمات.
- الوصول للتقارير.
- مراجعة أداء الموظفين.

## 4.6 Administrator

صلاحيات النظام الكاملة.

يشمل ذلك:

- إدارة المستخدمين.
- الأدوار.
- الصلاحيات.
- المحتوى.
- الوسائط.
- إعدادات الفندق.
- التواصل.
- كل الوحدات التشغيلية.
- التحكم في إظهار/إخفاء وتفعيل/تعطيل المزايا.
- Audit.

---

# 5. GUEST EXPERIENCE — فلسفة تجربة العميل

## 5.1 القاعدة

> **الضيف لا يجب أن يتعلم النظام. النظام هو الذي يتكيف مع الضيف.**

## 5.2 هدف تجربة الضيف

يمكن للضيف الانتقال من:

```text
أريد غرفة
```

إلى:

```text
طلب حجز واضح
```

بأقل عدد ممكن من القرارات.

## 5.3 لا نطلب بيانات بلا سبب

كل حقل يتم طلبه يجب أن يكون له سبب تشغيلي حقيقي.

إذا كان الحقل لا يحتاجه:

- الحجز.
- الفندق.
- التواصل.
- المتطلبات القانونية.
- التشغيل.

فلا يظهر في المرحلة الأولى.

## 5.4 التسجيل

الحساب الشخصي ليس بوابة إجبارية أمام العميل.

العميل يجب أن يستطيع:

- تصفح الفندق.
- رؤية الغرف.
- الاستفسار.
- بدء الحجز.

بدون إنشاء حساب ما لم يكن وجود الحساب ضروريًا للعملية.

يمكن لاحقًا ربط الطلب برقم الهاتف أو إنشاء حساب تلقائي/اختياري بحسب التصميم النهائي.

---

# 6. FAST BOOKING — رحلة الحجز المختصرة

## 6.1 الرحلة الأساسية

### Step 1

التاريخ + عدد الضيوف.

### Step 2

الغرف المتاحة + السعر + الصورة + أبرز المزايا.

### Step 3

الاسم + رقم WhatsApp/الهاتف.

### Step 4

تأكيد الطلب.

ثم يقرر النظام:

```text
Direct Confirmation
OR
WhatsApp Confirmation
OR
Admin Review
```

## 6.2 الرحلة المثالية

```text
Home
 ↓
Choose Dates
 ↓
Available Rooms
 ↓
Choose Room
 ↓
Name + Phone
 ↓
Confirm
 ↓
WhatsApp / Payment / Confirmation
```

## 6.3 الخدمات الإضافية

لا تجبر الخدمة الإضافية العميل على شاشة منفصلة إذا كانت غير ضرورية.

يمكن تقديمها:

- اختياريًا.
- بعد الحجز.
- أثناء مراجعة سريعة.
- أو عبر WhatsApp.

## 6.4 لا توجد خطوات لمجرد "اكتمال النظام"

الـBackend يمكن أن ينفذ عشرات العمليات داخليًا.

العميل لا يحتاج أن يراها كلها.

---

# 7. BOOKING MODES — أنماط الحجز

يجب أن يدعم النظام أكثر من مسار.

## 7.1 Direct Booking

عندما يستطيع النظام التحقق من:

- التوفر.
- السعر.
- قواعد الحجز.

يمكنه إنشاء طلب/حجز وفق السياسات.

## 7.2 WhatsApp Assisted Booking

عندما يحتاج الحجز:

- تأكيدًا بشريًا.
- تفاصيل خاصة.
- تفاوضًا.
- دفعًا يدويًا.
- ترتيبات إضافية.

يتم تحويل العملية إلى WhatsApp مع الاحتفاظ بسجلها في النظام.

## 7.3 Admin Created Booking

يمكن للموظف إنشاء الحجز نيابة عن العميل.

يجب أن يظهر:

```text
Created by Staff
```

مع تسجيل الموظف والوقت.

## 7.4 Walk-in Booking

حجز مباشر من الاستقبال.

يجب أن يعامل كنوع Workflow مستقل وليس كاختصار غير موثق.

---

# 8. WHATSAPP OPERATIONS — WhatsApp كطبقة تشغيل

## 8.1 المبدأ

WhatsApp ليس مجرد:

```text
Contact Us
```

بل قناة متكاملة بجانب التطبيق.

## 8.2 حالات الاستخدام

- استفسار.
- طلب حجز.
- تأكيد حجز.
- إرسال تفاصيل الحجز.
- طلب دفع/إثبات دفع.
- تعديل حجز.
- إلغاء.
- سؤال عن الخدمات.
- دعم أثناء الإقامة.

## 8.3 الربط مع النظام

كل طلب WhatsApp مهم يجب أن يكون قابلاً للربط بـ:

```text
Guest
Booking Request
Reservation
Room
Conversation Reference
Staff Owner
Status
```

## 8.4 حالات طلب التواصل

```text
New
Assigned
Contacted
Waiting Customer
Waiting Hotel
Confirmed
Converted
Closed
Cancelled
```

## 8.5 منع الفوضى

لا يكفي أن نفتح WhatsApp فقط.

لو أرسل العميل رسالة، يجب أن يعرف النظام:

- هل هناك طلب سابق؟
- هل هناك حجز؟
- ما الموظف المسؤول؟
- ما الحالة؟
- هل تم تحويل الاستفسار إلى حجز؟
- هل تم إغلاق الطلب؟

---

# 9. COMMUNICATION CENTER

لوحة الإدارة يجب أن تحتوي على مركز تواصل موحد.

يعرض:

- الطلبات الجديدة.
- طلبات الحجز.
- الطلبات التي تنتظر رد الفندق.
- الطلبات التي تنتظر العميل.
- الحجوزات المرتبطة.
- الموظف المسؤول.
- آخر إجراء.
- وقت آخر تواصل.

## 9.1 الهدف

عدم ضياع العميل بين:

```text
WhatsApp
Calls
App
Reception
Admin
```

## 9.2 Status Ownership

كل طلب يجب أن يكون له:

```text
Owner
Status
Priority
Last Activity
Next Action
```

---

# 10. HOTEL HOME — الصفحة الرئيسية

الصفحة الرئيسية ليست تجميعًا عشوائيًا للبلوكات.

يجب أن تحقق:

1. الثقة.
2. معرفة الفندق بسرعة.
3. رؤية الغرف.
4. معرفة السعر/التوافر.
5. الحجز أو التواصل.

## 10.1 ترتيب مقترح

```text
Hero
↓
Quick Booking
↓
Featured Rooms
↓
Why Hotel
↓
Offers
↓
Services
↓
Gallery
↓
Location
↓
Reviews
↓
Contact / WhatsApp
```

ويجب أن يكون هذا الترتيب قابلاً للتعديل من لوحة الإدارة.

---

# 11. CONTENT CONTROL — المحتوى قابل للتحكم بالكامل

## 11.1 قاعدة

أي محتوى يتغير باستمرار لا يجب أن يكون Hard-coded.

## 11.2 يجب أن يستطيع Admin التحكم في

### Home

- Hero.
- العنوان.
- النص.
- CTA.
- الصورة.
- الفيديو.
- ترتيب الأقسام.
- إظهار/إخفاء الأقسام.

### Rooms

- الاسم.
- الوصف.
- الصور.
- المميزات.
- السعر.
- حالة النشر.
- ترتيب الظهور.

### Services

- الاسم.
- الوصف.
- السعر.
- الصورة.
- الحالة.
- ترتيب الظهور.

### Offers

- الاسم.
- الوصف.
- الصورة.
- الشروط.
- التاريخ.
- الخصم.
- الحالة.

### Hotel Information

- الاسم.
- الوصف.
- الهاتف.
- WhatsApp.
- العنوان.
- الموقع.
- أوقات العمل.
- سياسات الفندق.

### Policies

- الحجز.
- الإلغاء.
- الدفع.
- Check-in.
- Check-out.
- الأطفال.
- الحيوانات إن وجدت.
- أي سياسة فعلية أخرى.

### FAQ

- السؤال.
- الإجابة.
- التصنيف.
- ترتيب الظهور.
- النشر.

---

# 12. CONTENT WORKFLOW

كل عنصر محتوى مهم يجب أن يدعم:

```text
Draft
Published
Hidden
Archived
```

## 12.1 Publish

يصبح مرئيًا للمستخدمين.

## 12.2 Hide

يختفي من الواجهة دون حذف البيانات.

## 12.3 Archive

يبقى محفوظًا تاريخيًا ولا يعرض.

## 12.4 Preview

يجب تمكين الإدارة من مشاهدة المحتوى قبل نشره.

---

# 13. MEDIA MANAGEMENT

لوحة الإدارة تتحكم في:

- رفع الصور.
- رفع الفيديو.
- حذف منطقي.
- إخفاء.
- إعادة ترتيب.
- تعيين صورة رئيسية.
- ربط الوسائط بالغرف والخدمات والأقسام.

يجب دعم:

```text
Alt Text
Caption
Display Order
Published
```

ويجب تحسين الصور للأداء.

---

# 14. ADMIN CONTROL CENTER — مركز التحكم

هذه أهم وحدة في المشروع.

## 14.1 الصفحة الرئيسية للمدير

يجب ألا تكون مجرد Cards رقمية.

يجب أن تجيب بصريًا عن:

### ماذا يحدث الآن؟

- حجوزات اليوم.
- وصول اليوم.
- مغادرة اليوم.
- الغرف المشغولة.
- الغرف المتاحة.
- الغرف المتوقفة.
- المدفوعات المنتظرة.
- طلبات الحجز الجديدة.
- طلبات WhatsApp.
- الخدمات المفتوحة.
- التنبيهات المهمة.

### ماذا يحتاج تدخلي الآن؟

قسم:

```text
Needs Attention
```

مثلاً:

- حجز ينتظر التأكيد.
- دفع يحتاج مراجعة.
- غرفة تحتاج صيانة.
- طلب ضيف متأخر.
- طلب WhatsApp بلا مسؤول.
- سعر غير محدد.
- مشكلة تشغيلية.

---

# 15. ADMIN INFORMATION ARCHITECTURE

يجب تقسيم لوحة الإدارة إلى طبقات مفهومة.

```text
Overview
│
├── Operations
│   ├── Reservations
│   ├── Calendar
│   ├── Rooms
│   ├── Guests
│   └── Service Requests
│
├── Commerce
│   ├── Rates
│   ├── Offers
│   ├── Payments
│   └── Invoices
│
├── Communication
│   ├── WhatsApp Requests
│   ├── Contact Requests
│   └── Notifications
│
├── Content
│   ├── Homepage
│   ├── Rooms
│   ├── Services
│   ├── Offers
│   ├── Gallery
│   ├── FAQ
│   └── Policies
│
├── Insights
│   ├── Reports
│   ├── Analytics
│   └── Audit
│
└── System
    ├── Users
    ├── Roles
    ├── Permissions
    ├── Settings
    └── Integrations
```

---

# 16. ADMIN CRUD STANDARD

كل كيان إداري يجب أن يملك نمطًا متسقًا.

## List

- Search.
- Filter.
- Sort.
- Pagination.
- Status.
- Bulk actions عند الحاجة.

## View

- Summary.
- Details.
- Related data.
- Activity.
- History.

## Create

- Validation.
- Preview.
- Save Draft عند الحاجة.

## Edit

- تعديل آمن.
- مقارنة التغييرات عند العمليات الحساسة.
- Audit.

## Actions

حسب الصلاحيات:

- Activate.
- Deactivate.
- Publish.
- Unpublish.
- Hide.
- Restore.
- Archive.
- Approve.
- Reject.
- Cancel.

---

# 17. ROOM MANAGEMENT

## 17.1 Room Type

مثل:

- Standard.
- Deluxe.
- Suite.
- Family.

## 17.2 Physical Room

مثل:

- 101.
- 102.
- 201.

## 17.3 Room Type Data

- الاسم العربي.
- الاسم الإنجليزي.
- الوصف.
- الصور.
- المساحة.
- السعة.
- الأسرة.
- المزايا.
- السعر الأساسي.
- سياسات الحجز.
- حالة النشر.

## 17.4 Physical Room Data

- الرقم.
- النوع.
- الطابق.
- الحالة.
- ملاحظات.
- صيانة.
- تاريخ آخر تنظيف عند الحاجة.

---

# 18. ROOM STATES

```text
Available
Reserved
Occupied
Cleaning
Maintenance
Blocked
Out of Service
```

لا يجوز أن تغير واجهة الموظف الحالة بلا تحقق من قواعد التشغيل.

---

# 19. AVAILABILITY ENGINE

التوفر ليس مجرد:

```text
Total Rooms - Reservations
```

بل يعتمد على:

- الغرفة.
- التاريخ.
- الحجوزات.
- حالة الغرفة.
- الصيانة.
- الحظر.
- قواعد الإشغال.
- أي قواعد تشغيلية أخرى.

## 19.1 Critical Rule

لا يسمح النظام بحجز متعارض.

التحقق يجب أن يكون Server-side.

---

# 20. PRICING ENGINE

يجب فصل السعر عن الواجهة.

يمكن أن يعتمد على:

- السعر الأساسي.
- التاريخ.
- عدد الليالي.
- عدد الأشخاص.
- نوع الغرفة.
- العرض.
- الخصم.
- الخدمة.
- الرسوم/الضرائب إذا كانت مطبقة.

## 20.1 Price Snapshot

عند تأكيد الحجز يجب حفظ نسخة من النتيجة:

```text
Room Price
Discount
Services
Fees
Total
Currency
```

حتى لا تتغير قيمة الحجز التاريخي إذا تغيّر السعر لاحقًا.

---

# 21. OFFERS

العرض يجب أن يكون Data Object وليس نصًا يدويًا.

يدعم:

- الاسم.
- الوصف.
- الصور.
- البداية.
- النهاية.
- نوع الخصم.
- قيمة الخصم.
- الغرف المشمولة.
- الشروط.
- الحالة.

---

# 22. RESERVATION DOMAIN

## 22.1 Reservation

يحتوي على:

- ID.
- Confirmation Number.
- Guest.
- Room Type.
- Room.
- Check-in.
- Check-out.
- Adults.
- Children.
- Quantity.
- Pricing Snapshot.
- Services.
- Total.
- Paid.
- Remaining.
- Currency.
- Payment Status.
- Booking Status.
- Cancellation Status.
- Source.
- Created By.
- Created At.

## 22.2 Booking Source

يجب معرفة مصدر الحجز:

```text
App
Website
WhatsApp
Reception
Phone
Admin
Other
```

---

# 23. RESERVATION STATES

```text
Draft
Pending
Awaiting Confirmation
Confirmed
Checked-In
Checked-Out
Completed
Cancelled
No-Show
Rejected
```

يجب تعريف الانتقالات المسموح بها بدل تغيير الحالة عشوائيًا.

---

# 24. RESERVATION STATE MACHINE

مثال:

```text
Draft
  ↓
Pending
  ↓
Awaiting Confirmation
  ↓
Confirmed
  ↓
Checked-In
  ↓
Checked-Out
  ↓
Completed
```

مسارات بديلة:

```text
Pending → Rejected
Pending → Cancelled
Confirmed → Cancelled
Confirmed → No-Show
```

كل انتقال حساس يجب أن يملك:

- Actor.
- Reason عند الحاجة.
- Timestamp.
- Audit.

---

# 25. BOOKING REQUEST VS RESERVATION

يجب الفصل بين:

## Booking Request

رغبة العميل في الحجز.

## Reservation

حجز مؤكد/معتمد وفق قواعد الفندق.

هذا الفصل مهم جدًا لبيئة WhatsApp.

مثال:

```text
Guest Request
↓
Booking Request
↓
Admin Review
↓
Confirmed Reservation
```

وبالتالي لا نعتبر كل رسالة WhatsApp حجزًا مؤكدًا.

---

# 26. PAYMENTS

النظام يجب ألا يفترض وجود بوابة دفع واحدة.

Payment Abstraction:

```text
PaymentMethod
PaymentStatus
PaymentReference
Amount
Currency
RecordedBy
CreatedAt
```

يمكن دعم:

- Cash.
- Bank Transfer.
- Local Payment Method.
- Online Gateway عندما تتوفر.
- Manual Confirmation.

## 26.1 إثبات الدفع

عند استخدام الدفع اليدوي، يجب دعم:

- Reference.
- صورة/ملف إثبات عند الحاجة.
- حالة المراجعة.
- من راجع.
- ملاحظات.

---

# 27. PAYMENT STATES

```text
Pending
Submitted
Under Review
Paid
Partially Paid
Failed
Cancelled
Refunded
Partially Refunded
```

---

# 28. COMMERCIAL SAFETY

لا يسمح للواجهة أن تقرر وحدها:

- السعر النهائي.
- توفر الغرفة.
- حالة الدفع.
- الاسترداد.
- الصلاحيات.

Flutter يرسل Intent/Request.

Backend يقرر.

---

# 29. GUEST PROFILE

البيانات الأساسية:

- الاسم.
- الهاتف.
- WhatsApp.
- البريد عند الحاجة.
- ملاحظات تشغيلية مصرح بها.
- سجل الحجوزات.

يجب حماية البيانات.

---

# 30. GUEST ACCOUNT

الحساب يجب أن يكون بسيطًا.

يعرض:

- بيانات المستخدم.
- الحجوزات.
- الطلبات.
- الإشعارات.
- طرق التواصل.

لا يتم بناء نظام حساب معقد إذا لم تكن هناك قيمة فعلية.

---

# 31. SERVICE REQUESTS

الخدمات يمكن أن تشمل حسب الواقع:

- تنظيف.
- مناشف.
- صيانة.
- طعام.
- طلب خاص.
- خدمات أخرى.

## 31.1 Request

- ID.
- Guest.
- Room.
- Booking.
- Category.
- Description.
- Priority.
- Status.
- Assigned To.
- Created At.
- Completed At.

---

# 32. SERVICE REQUEST STATES

```text
New
Accepted
Assigned
In Progress
Waiting
Completed
Cancelled
Rejected
```

---

# 33. NOTIFICATIONS

يجب أن تكون طبقة مستقلة.

أحداث نموذجية:

- طلب حجز جديد.
- تأكيد.
- تغيير الحجز.
- الدفع.
- التذكير.
- الإلغاء.
- طلب خدمة.
- اكتمال الطلب.

لا يتم ربط الإشعار مباشرة بكل شاشة.

---

# 34. ADMIN NOTIFICATION CENTER

يعرض:

- ما يحتاج الانتباه.
- الرسائل التشغيلية.
- التغييرات المهمة.
- فشل العمليات.

كل إشعار يجب أن يملك رابطًا إلى العنصر المرتبط به.

مثال:

```text
New Booking Request
→ Open Booking
```

---

# 35. CUSTOMER COMMUNICATION

يجب أن يستطيع النظام توليد بيانات اتصال واضحة:

- اسم العميل.
- رقم الحجز.
- التواريخ.
- الغرفة.
- المبلغ.
- حالة الدفع.

وتوفير CTA مناسب:

```text
Open WhatsApp
Call Hotel
View Booking
```

---

# 36. REPORTING

التقارير يجب أن تخدم قرارًا وليس مجرد عرض أرقام.

## أساسية

- الحجوزات.
- الإشغال.
- الإيرادات.
- المدفوعات.
- المتبقي.
- الإلغاءات.
- الغرف.
- الخدمات.
- مصادر الحجز.

## الزمن

- اليوم.
- أمس.
- الأسبوع.
- الشهر.
- السنة.
- فترة مخصصة.

---

# 37. DASHBOARD METRICS

يجب أن تكون المؤشرات قابلة للنقر للوصول للبيانات.

مثال:

```text
Today's Reservations: 12
↓
Open Filtered Reservations
```

لا تكون الـCards مجرد أرقام تجميلية.

---

# 38. AUDIT LOG

يجب تسجيل العمليات الحساسة:

```text
Actor
Action
Entity
Entity ID
Old Value
New Value
Reason
Timestamp
```

أمثلة:

- تغيير سعر.
- إلغاء حجز.
- تأكيد دفع.
- تعديل حالة غرفة.
- تغيير صلاحية.
- نشر محتوى.
- إخفاء خدمة.

---

# 39. ADMIN PERMISSIONS

الصلاحيات يجب أن تكون منفصلة عن الدور قدر الإمكان.

مثال:

```text
reservation.view
reservation.create
reservation.edit
reservation.cancel
reservation.confirm
payment.view
payment.record
payment.approve
room.view
room.edit
room.status
content.view
content.edit
content.publish
report.view
user.manage
system.manage
```

---

# 40. ROLE BASED ACCESS

الدور يجمع مجموعة صلاحيات.

لكن النظام لا يعتمد على اسم الدور وحده في القرارات الحساسة.

يتم التحقق من Permission فعلي.

---

# 41. CONTENT PERMISSIONS

من الممكن أن يملك موظف المحتوى صلاحيات:

- Edit.
- Draft.
- Preview.

لكن لا يملك:

- Publish حساس.
- تغيير أسعار.
- تعديل المدفوعات.

---

# 42. SETTINGS CENTER

لوحة الإدارة يجب أن تحتوي Settings منظمة.

## Hotel

- الاسم.
- الوصف.
- الاتصال.
- العنوان.
- الموقع.

## Booking

- مدة الإقامة.
- مواعيد Check-in.
- مواعيد Check-out.
- قواعد الحجز.

## Cancellation

- السياسات.

## Contact

- الهاتف.
- WhatsApp.
- البريد.
- روابط التواصل.

## Localization

- اللغة.
- العملة.
- تنسيق التاريخ.

## Notifications

- قنوات الإرسال.

## Integrations

- خدمات خارجية.

---

# 43. FEATURE FLAGS

يجب دعم التشغيل/التعطيل المنضبط للمزايا.

مثلاً:

```text
Online Payment: ON/OFF
Reviews: ON/OFF
Offers: ON/OFF
Service Requests: ON/OFF
Guest Accounts: ON/OFF
```

إيقاف ميزة يجب ألا يكسر النظام.

---

# 44. ADMIN CONTENT BUILDER — بمستوى عملي

لا يلزم بناء Page Builder معقد مثل الأنظمة العالمية.

لكن يجب دعم:

```text
Section
Title
Description
Image
CTA
Order
Visible
```

مع Sections معروفة مسبقًا وقابلة لإعادة الترتيب.

هذا أفضل من بناء محرر حر معقد يصعب على الموظفين استخدامه.

---

# 45. UX FOR ADMIN

لوحة الإدارة يجب أن تكون:

- نظيفة.
- عملية.
- سريعة.
- كثيفة معلومات عند الحاجة.
- لا تحتوي على زخرفة تعيق العمل.
- تدعم اختصارات الإجراءات المتكررة.
- تستخدم Dialog/Drawer بدل الانتقال المستمر بين الصفحات عند العمليات الصغيرة.

---

# 46. MOBILE UX FOR GUEST

يجب أن يكون:

- سريعًا.
- واضحًا.
- بإجراءات كبيرة.
- صفحات قصيرة.
- CTA واضح.
- صور جيدة.
- دعم RTL.
- Loading واضح.
- Errors مفهومة.

---

# 47. WEB UX

## Guest Website

واجهة تسويقية فندقية.

## Admin Web

واجهة تشغيلية إدارية.

لا يتم استخدام نفس Navigation أو Layout بينهما.

---

# 48. PLATFORM ARCHITECTURE

```text
                        GUEST
                          │
              ┌───────────┴───────────┐
              │                       │
         Mobile App              Website
              │                       │
              └───────────┬───────────┘
                          │
                      API / Backend
                          │
         ┌────────────────┼────────────────┐
         │                │                │
     Business         Communications     Data
      Logic               │                │
         │             WhatsApp          DB
         │             Notifications
         │
   Booking Engine
   Availability
   Pricing
   Payments
   Permissions
   Content
   Reporting
                          │
                     ADMIN WEB
```

---

# 49. BACKEND RESPONSIBILITIES

Backend مسؤول عن:

- Authentication.
- Authorization.
- Booking Engine.
- Availability.
- Pricing.
- Payment State.
- Reservation State.
- Content.
- Notifications.
- Reporting.
- Audit.
- Data Integrity.

---

# 50. API DESIGN

يجب أن تكون الـAPI منظمة حسب المجالات.

```text
/auth
/users
/guests
/rooms
/room-types
/availability
/booking-requests
/reservations
/payments
/services
/service-requests
/offers
/content
/media
/notifications
/reports
/settings
/audit
```

---

# 51. DATABASE CORE

الجداول الأساسية المقترحة:

```text
users
roles
permissions
user_roles
role_permissions

guests

room_types
rooms
room_amenities
amenities
room_images

rate_plans
room_rates

booking_requests
reservations
reservation_guests
reservation_rooms

reservation_services
services
service_requests

payments
refunds
payment_proofs

offers
offer_rooms

notifications

content_pages
content_sections
media_assets

reviews

hotel_settings
booking_settings
contact_settings
currency_settings
cancellation_policies

audit_logs

communication_threads
communication_events

feature_flags
```

---

# 52. DATA INTEGRITY

يجب استخدام:

- Foreign Keys.
- Unique Constraints.
- Indexes.
- Transactions.
- Timestamps.
- Soft Delete عند الحاجة.
- Referential Integrity.

---

# 53. BOOKING TRANSACTION

عملية الحجز الحرجة يجب أن تكون ذرية قدر الإمكان:

```text
Validate Request
↓
Check Availability
↓
Calculate Price
↓
Create Reservation / Booking Request
↓
Create Payment Record if applicable
↓
Commit
↓
Emit Notification
```

عند فشل خطوة حرجة يجب عدم ترك بيانات نصف مكتملة.

---

# 54. CONCURRENCY

يجب التعامل مع حالتين:

```text
User A checks room
User B checks room
Both attempt booking
```

يجب أن يمنع الـBackend تأكيد حجز متعارض.

---

# 55. ERROR MODEL

كل Feature يجب أن تدعم:

```text
Loading
Success
Empty
Error
Unauthorized
Offline
Timeout
Retry
```

لا تظهر Exceptions التقنية للعميل.

---

# 56. ERROR HANDLING

رسالة المستخدم:

> حدث خطأ أثناء تنفيذ العملية. حاول مرة أخرى.

أما داخليًا:

- Log.
- Error Code.
- Correlation ID عند الحاجة.
- Context آمن.

---

# 57. OBSERVABILITY

يجب تسجيل:

- API errors.
- Booking failures.
- Payment failures.
- Authentication failures.
- Critical state transitions.

ولا تسجل:

- كلمات المرور.
- بيانات حساسة غير ضرورية.
- Tokens.

---

# 58. SECURITY

يجب تطبيق:

- Authentication.
- Authorization.
- Secure Tokens.
- HTTPS.
- Server Validation.
- Rate Limiting.
- Audit.
- Input Validation.
- Secure Secrets Management.

---

# 59. PRIVACY

يجب عدم كشف بيانات العميل لموظف لا يحتاجها.

القاعدة:

> Least Privilege.

---

# 60. RTL & LOCALIZATION

من البداية:

- العربية.
- الإنجليزية.

كل النصوص المهمة تأتي من طبقة Localization/CMS حسب طبيعتها.

لا يتم Hard-code للنصوص القابلة للإدارة.

يجب اختبار:

- RTL.
- الأرقام.
- الجداول.
- التواريخ.
- الأيقونات.
- التنقل.

---

# 61. CURRENCY

المبالغ يجب أن تخزن مع العملة.

مثال:

```text
amount
currency
```

ولا يوجد مبلغ بلا Currency.

---

# 62. DATE & TIME

التواريخ يجب أن تكون:

- موحدة.
- قابلة للعرض المحلي.
- محفوظة بطريقة آمنة.
- غير معتمدة على نص يدوي.

---

# 63. FLUTTER ARCHITECTURE

استخدام:

```text
Clean Architecture
+
Feature-Based Structure
+
Repository Pattern
+
Dependency Injection
+
Central Error Handling
+
Central Logging
```

## 63.1 State Management

يتم اختيار حل واحد فقط مثل:

- Riverpod

أو بديل واضح يتم اعتماده مرة واحدة.

ممنوع خلط عدة أنظمة بلا سبب.

---

# 64. FLUTTER PROJECT STRUCTURE

```text
lib/
├── app/
│   ├── app.dart
│   ├── router/
│   ├── theme/
│   ├── localization/
│   └── config/
│
├── core/
│   ├── error/
│   ├── network/
│   ├── storage/
│   ├── logging/
│   ├── security/
│   ├── utils/
│   └── widgets/
│
├── features/
│   ├── home/
│   ├── rooms/
│   ├── availability/
│   ├── booking/
│   ├── reservations/
│   ├── payments/
│   ├── services/
│   ├── offers/
│   ├── reviews/
│   ├── notifications/
│   ├── profile/
│   ├── communication/
│   └── admin/
│
└── main.dart
```

---

# 65. BUSINESS LOGIC SEPARATION

ممنوع:

```text
Widget
    ↓
Complex Booking Calculation
```

المطلوب:

```text
UI
 ↓
Controller / Notifier
 ↓
Use Case
 ↓
Repository
 ↓
API
```

---

# 66. DESIGN SYSTEM

يجب وجود Design System موحد يشمل:

- Colors.
- Typography.
- Spacing.
- Radius.
- Shadows.
- Buttons.
- Inputs.
- Cards.
- Dialogs.
- Sheets.
- Tables.
- Badges.
- Icons.

---

# 67. MOBILE DESIGN

مكونات قابلة لإعادة الاستخدام:

```text
MobileRoomCard
MobileBookingCard
MobileBookingSummary
MobileBottomNavigation
MobileDateSelector
MobileGuestSelector
WhatsAppAction
```

---

# 68. ADMIN WEB COMPONENTS

```text
AdminSidebar
AdminTopBar
MetricCard
DataTable
FilterBar
SearchField
StatusBadge
EntityDrawer
ConfirmationDialog
AuditTimeline
BookingCalendar
RoomBoard
```

---

# 69. RESPONSIVE VS ADAPTIVE

يجب دعم الاثنين.

## Responsive

الأحجام والمسافات والأعمدة.

## Adaptive

تغيير تجربة الاستخدام نفسها.

الهاتف:

```text
Bottom Navigation
Cards
Short flows
```

الويب:

```text
Sidebar
Tables
Multi-column
Filters
Charts
```

---

# 70. SEARCH

البحث في الإدارة يجب أن يكون عمليًا.

يمكن البحث في:

- Booking ID.
- Guest Name.
- Phone.
- Room.
- Status.
- Date.
- Payment Reference.

---

# 71. FILTERS

يجب دعم:

- Date.
- Status.
- Source.
- Room Type.
- Payment.
- Assigned Staff.
- Priority.

---

# 72. AUDITABLE ACTIONS

أي إجراء يغير حقيقة تجارية يجب أن يسجل.

أمثلة:

```text
Approve Reservation
Reject Reservation
Change Price
Record Payment
Refund Payment
Change Room Status
Cancel Booking
Publish Content
Hide Content
Grant Permission
```

---

# 73. CONTENT AUDIT

تعديل المحتوى المهم يسجل:

```text
Who
What
Before
After
When
```

---

# 74. NO HARD DELETE FOR BUSINESS HISTORY

لا يتم حذف:

- الحجوزات.
- المدفوعات.
- الفواتير.
- السجلات التدقيقية.

بدل ذلك:

- Cancel.
- Archive.
- Soft Delete.

بحسب نوع البيانات.

---

# 75. HOUSEKEEPING

يدعم:

- قائمة الغرف.
- حالة التنظيف.
- المهام.
- الأولوية.
- المسؤول.
- وقت التنفيذ.

لا حاجة لبناء نظام ضخم إذا لم يكن ضمن احتياج الفندق.

---

# 76. INVOICING

الفاتورة يجب أن تحتوي على:

- رقم الفاتورة.
- الفندق.
- العميل.
- الحجز.
- الغرفة.
- الخدمات.
- الخصم.
- الرسوم.
- الإجمالي.
- المدفوع.
- المتبقي.
- العملة.

---

# 77. PDF & PRINTING

يجب دعم إخراج:

- الفواتير.
- تأكيدات الحجز.
- التقارير.

حسب المنصة والاحتياج.

---

# 78. OFFLINE STRATEGY

النظام ليس Offline-first للحجز.

لكن يمكن دعم:

- Cache.
- حالة الاتصال.
- Retry.
- Draft محلي عند الحاجة.

لا يتم تأكيد حجز حقيقي دون تحقق Backend.

---

# 79. ANALYTICS

يجب معرفة:

- مصادر الحجوزات.
- الغرف الأكثر مشاهدة.
- البحث.
- التحويل من استفسار إلى حجز.
- التحويل من WhatsApp إلى حجز عندما يمكن قياسه.
- الأداء التشغيلي.

---

# 80. CONVERSION FUNNEL

نموذج قياس:

```text
Visitor
↓
Room View
↓
Availability Search
↓
Booking Request
↓
WhatsApp / Confirmation
↓
Reservation
↓
Completed Stay
```

الهدف ليس زيادة الخطوات.

الهدف تقليل التسرب.

---

# 81. ADMIN WORKFLOWS

## 81.1 New Booking Request

```text
New
↓
Review
↓
Available?
├── No → Offer Alternatives
└── Yes → Confirm / WhatsApp
```

## 81.2 Payment Review

```text
Submitted
↓
Review
├── Accept → Paid
└── Reject → Needs Action
```

## 81.3 Service Request

```text
New
↓
Assign
↓
In Progress
↓
Completed
```

---

# 82. USER ↔ ADMIN SYNCHRONIZATION

هذه قاعدة محورية.

كل حدث مهم عند العميل يجب أن يظهر للإدارة إذا كان ذا صلة.

مثلاً:

```text
Guest submits booking request
→ Admin receives request

Admin changes booking
→ Guest sees updated state

Payment marked paid
→ Guest sees paid

Admin cancels
→ Guest notified

Guest requests service
→ Staff sees service request

Staff completes service
→ Guest sees completed
```

---

# 83. SINGLE SOURCE OF TRUTH

يجب ألا يوجد:

```text
Booking status in app
Booking status in admin
Booking status in WhatsApp
```

كحقائق مستقلة.

الحقيقة هي Backend.

الواجهات تعرض الحالة.

---

# 84. COMMUNICATION TRACE

عند انتقال الطلب عبر WhatsApp يجب ألا تضيع علاقته بالنظام.

يجب أن يحتوي السجل على:

```text
Request
Guest
Booking
Channel
Staff
Status
Created At
Last Activity
```

---

# 85. UX WHEN SYSTEM NEEDS HUMAN ACTION

بدل:

> خطأ.

يفضل:

> طلبك وصل للفندق ويجري تأكيده الآن.

مع CTA:

> التواصل عبر WhatsApp

أو:

> متابعة الطلب.

---

# 86. EMPTY STATES

مثال:

> لا توجد حجوزات حاليًا.

مع CTA مناسب.

في الإدارة:

> لا توجد طلبات جديدة.

---

# 87. LOADING

استخدام:

- Skeleton.
- Progress.
- Inline loading.

تجنب تجميد التطبيق.

---

# 88. PERFORMANCE

يجب تحسين:

- الصور.
- API Calls.
- Pagination.
- Caching.
- Rendering.
- DataTable.
- Gallery.

---

# 89. ACCESSIBILITY

يجب دعم:

- Contrast جيد.
- Touch Targets.
- Screen Reader Labels.
- Keyboard Navigation للويب.
- Focus States.

---

# 90. DEEP LINKS

دعم روابط للمحتوى المهم:

```text
/rooms/:id
/offers/:id
/booking/:id
```

بحسب بنية المنتج النهائية.

---

# 91. WEBSITE SEO

بالقدر المناسب للـWeb:

- Titles.
- Metadata.
- Share previews.
- Structured content.
- Performance.
- Friendly URLs.

---

# 92. TESTING STRATEGY

## Unit Tests

- Availability.
- Pricing.
- Discounts.
- State transitions.
- Cancellation.
- Payment states.

## Widget Tests

- Room card.
- Booking flow.
- Admin forms.
- Login.

## Integration Tests

- Search.
- Select.
- Request.
- Confirmation.
- Payment recording.
- Admin visibility.

## E2E

رحلة كاملة من العميل حتى التشغيل.

---

# 93. ACCEPTANCE JOURNEY — الرحلة الأساسية

يجب أن ينجح السيناريو:

```text
Guest opens platform
↓
Sees hotel
↓
Selects dates
↓
Sees available rooms
↓
Selects room
↓
Enters name + phone
↓
Submits request
↓
System creates booking request
↓
Admin sees request
↓
Admin confirms or opens WhatsApp
↓
Guest receives confirmation
↓
Reservation becomes visible
↓
Reception sees reservation
↓
Check-in
↓
Service request
↓
Staff completes request
↓
Check-out
↓
Invoice
↓
Review
```

---

# 94. WHATSAPP ACCEPTANCE TEST

يجب أن ينجح:

```text
Guest
↓
Requests Booking
↓
Chooses WhatsApp
↓
System prepares structured information
↓
WhatsApp opens
↓
Staff receives request
↓
Admin links request
↓
Admin confirms
↓
Reservation created/confirmed
↓
Guest receives confirmation
```

---

# 95. ADMIN MASTER CONTROL ACCEPTANCE TEST

الـAdministrator يجب أن يستطيع، وفق الصلاحيات:

### Content

- Add.
- Edit.
- Hide.
- Publish.
- Reorder.

### Rooms

- Add.
- Edit.
- Disable.
- Change status.
- Change price according to permission.

### Services

- Add.
- Edit.
- Hide.
- Change price.

### Offers

- Create.
- Start.
- Stop.
- Archive.

### Reservations

- View.
- Create.
- Approve.
- Edit.
- Cancel.
- Confirm payment where authorized.

### Users

- Add.
- Disable.
- Assign Role.
- Adjust Permissions.

### Settings

- Change contact channels.
- Change hotel information.
- Manage feature flags.
- Manage booking policies.

كل ذلك عبر UI ولا يتطلب تعديل الكود.

---

# 96. ADMIN SAFETY

الإدارة الكاملة لا تعني الفوضى.

الإجراءات الحساسة تحتاج:

- Confirmation.
- Permission.
- Audit.
- Reason عند الحاجة.

---

# 97. BULK ACTIONS

يمكن دعم الإجراءات الجماعية عندما تكون آمنة ومفيدة.

مثل:

- نشر عدة محتويات.
- إخفاء عدة خدمات.
- تغيير حالة عناصر مختارة.

العمليات التجارية الحساسة يجب الحذر منها.

---

# 98. DESIGN QUALITY BAR

المشروع يجب أن يبدو:

- فندقيًا.
- راقيًا.
- هادئًا.
- سريعًا.
- موثوقًا.
- واضحًا.

ولا يجب أن يبدو:

- متجرًا.
- لوحة محاسبية في واجهة العميل.
- قالبًا جاهزًا.
- تطبيقًا مزدحمًا.

---

# 99. CONTENT QUALITY

أي نص يظهر للعميل يجب أن يكون:

- واضحًا.
- قصيرًا.
- طبيعيًا.
- غير تقني.
- متناسقًا مع العلامة التجارية.

---

# 100. SOURCE OF CONFIGURATION

كل ما يحتمل تغييره تشغيليًا يجب أن يكون Configurable.

مثال:

```text
Hotel Name
Phone
WhatsApp
Address
Opening Hours
Check-in Time
Check-out Time
Policies
Room Prices
Offers
Content
Feature Flags
```

---

# 101. DEVELOPMENT PHASES

## Phase 0 — Understanding

قبل أي كود:

- دراسة الوثيقة.
- تعريف المؤسسة.
- تعريف المستخدمين.
- تعريف العمليات.
- تحديد ما هو Automated وما هو Human-assisted.
- تحديد WhatsApp flows.
- تحديد إدارة المحتوى.

**Output:**
Business Model + Domain Map + User/Staff Journeys.

## Phase 1 — UX & Flow

- Guest Journey.
- Booking Journey.
- WhatsApp Journey.
- Admin Journey.
- Staff Journey.

**Output:**
Flow Maps.

## Phase 2 — Architecture

- Backend.
- Database.
- API.
- Auth.
- Permissions.
- Booking Engine.
- Pricing Engine.
- Availability.

**Output:**
Technical Architecture.

## Phase 3 — Design System

- Mobile.
- Guest Web.
- Admin Web.

**Output:**
Reusable Design System.

## Phase 4 — Backend Core

ابدأ بالمنطق وليس بالصفحات.

## Phase 5 — Guest Experience

- Home.
- Rooms.
- Search.
- Booking.
- Confirmation.
- WhatsApp.

## Phase 6 — Admin Control

- Dashboard.
- Reservations.
- Rooms.
- Guests.
- Communication.
- Content.
- Settings.

## Phase 7 — Operations

- Check-in.
- Check-out.
- Services.
- Payments.
- Invoices.

## Phase 8 — Reports & Audit

## Phase 9 — Testing

## Phase 10 — Security Review

## Phase 11 — Production Readiness

---

# 102. IMPLEMENTATION ORDER

يجب ألا يتم تنفيذ المشروع بترتيب "الشاشات الأسهل".

الترتيب الأفضل:

```text
Domain
↓
Business Rules
↓
Data Model
↓
Backend Core
↓
Core UI
↓
Guest Flow
↓
Admin Flow
↓
Operations
↓
Reports
↓
Polish
```

---

# 103. AI DEVELOPMENT RULES

هذه القواعد موجهة مباشرة إلى نموذج الذكاء الاصطناعي المنفذ.

## MUST

قبل كل Feature:

1. اقرأ هذا الـPLAN.
2. حدد هدف الـFeature.
3. حدد Actor.
4. حدد Business Rules.
5. حدد Data.
6. حدد Permissions.
7. حدد حالات الخطأ.
8. حدد تأثير الـFeature على الوحدات الأخرى.
9. ثم ابدأ التنفيذ.

## MUST NOT

لا تبدأ بإنشاء Widget أو Page مباشرة بدون فهم ما وراءها.

---

# 104. CROSS-FEATURE IMPACT

كل تغيير يجب فحص أثره.

مثال:

تغيير سعر الغرفة يؤثر على:

- Room.
- Rate.
- Booking.
- Reports.
- Offers.
- Invoice.

لكن لا يغير قيمة الحجز التاريخي المؤكد.

---

# 105. BACKWARD COMPATIBILITY

تغيير المحتوى أو الأسعار أو الإعدادات الحالية لا يجب أن يكسر الحجوزات القديمة.

---

# 106. DEFINITION OF READY

قبل تنفيذ Feature:

```text
[ ] Purpose defined
[ ] Actor defined
[ ] Data defined
[ ] Rules defined
[ ] Permissions defined
[ ] API defined
[ ] Error states defined
[ ] Audit requirements defined
[ ] Dependencies known
```

---

# 107. DEFINITION OF DONE

Feature لا تعتبر مكتملة حتى:

```text
[ ] UI complete
[ ] Business logic complete
[ ] API integrated
[ ] Validation complete
[ ] Loading state
[ ] Empty state
[ ] Error state
[ ] Permission check
[ ] Audit if applicable
[ ] Tests
[ ] Responsive/adaptive behavior
[ ] RTL
```

---

# 108. PROJECT COMPLETION

المشروع لا يعتبر مكتملًا بمجرد أن:

- التطبيق يفتح.
- الصفحات تظهر.
- API تعمل.

بل عندما ينجح التشغيل الحقيقي.

## Guest

- يستطيع معرفة الفندق.
- العثور على غرفة.
- بدء الحجز.
- التواصل.
- استلام النتيجة.

## Hotel

- يستقبل الطلب.
- يراه في الإدارة.
- يتعامل معه.
- يغير حالته.
- يدير الغرفة.
- يتابع الدفع.
- يتابع الخدمة.
- يخرج التقرير.

---

# 109. PRODUCTION READINESS

قبل الإنتاج:

- Build succeeds.
- No critical crashes.
- Database migrations verified.
- API security reviewed.
- Permissions verified.
- Booking concurrency tested.
- Payment paths tested.
- WhatsApp flows tested.
- Admin actions audited.
- Backups configured.
- Monitoring configured.
- Error reporting configured.
- Privacy reviewed.

---

# 110. FUTURE EXPANSION

يجب أن يسمح التصميم مستقبلًا بإضافة:

- Loyalty.
- Membership.
- Transfers.
- Restaurant.
- Events.
- Meeting Rooms.
- Advanced Revenue Management.
- Multi-branch.
- Corporate Accounts.
- Coupons.
- Gift Cards.
- OTA integrations.
- WhatsApp automation.

لكن:

> **لا تضف أي Feature مستقبلية للنسخة الحالية إلا إذا كانت ضمن نطاق العمل الفعلي.**

---

# 111. WHAT SHOULD NOT BE OVERBUILT

لا نبني من اليوم الأول:

- CRM عملاق.
- Page Builder حر بالكامل.
- نظام محادثات معقدًا إذا كان WhatsApp يكفي.
- عشرات أنواع الحسابات.
- نظام دفع عالمي بلا حاجة.
- تقارير لا يحتاجها الفندق.
- Features لا تخدم القيمة الأساسية.

المبدأ:

> **Build the minimum complete system, not the minimum number of screens.**

---

# 112. FINAL OPERATING MODEL

النظام النهائي يجب أن يعمل هكذا:

```text
                         HOTEL
                           │
          ┌────────────────┼────────────────┐
          │                │                │
        GUEST          COMMUNICATION      ADMIN
          │             WHATSAPP            │
          │                │                │
          └────────────────┼────────────────┘
                           │
                         API
                           │
                  BUSINESS LOGIC
                           │
       ┌───────────────────┼───────────────────┐
       │                   │                   │
   Booking Engine     Operations          Content
   Availability       Payments             Media
   Pricing            Services             Settings
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │
                        DATABASE
                           │
                         AUDIT
```

---

# 113. GOLDEN RULES

## Rule 1

> **Simplify the customer. Do not simplify the business logic incorrectly.**

## Rule 2

> **Complexity belongs inside the system, not in the customer's face.**

## Rule 3

> **WhatsApp is a workflow channel, not merely a contact button.**

## Rule 4

> **The Admin Panel is the operational control center.**

## Rule 5

> **Backend is the source of truth.**

## Rule 6

> **Every important business action must be traceable.**

## Rule 7

> **Content must be editable without rebuilding the application.**

## Rule 8

> **A screen is valuable only when it serves a real workflow.**

## Rule 9

> **Every state transition must have a reason and an owner.**

## Rule 10

> **Build for the real hotel and real customer behavior, not for feature-count marketing.**

---

# 114. FINAL ACCEPTANCE CRITERIA

المشروع مقبول فقط إذا تحقق الآتي:

### Understanding

- [ ] تم تعريف الغاية.
- [ ] تم تعريف المستخدمين.
- [ ] تم تعريف العمليات.
- [ ] تم تعريف مسؤوليات كل Actor.
- [ ] تم تعريف Human vs Automated flows.

### Guest

- [ ] يمكن التصفح دون تسجيل إجباري غير ضروري.
- [ ] الحجز سريع.
- [ ] الخطوات قليلة.
- [ ] WhatsApp متاح بوضوح.
- [ ] الحالات واضحة.
- [ ] الأخطاء مفهومة.

### Booking

- [ ] التوفر صحيح.
- [ ] منع Double Booking يعمل.
- [ ] السعر يحسب Server-side.
- [ ] الحجز مرتبط بالعميل.
- [ ] تاريخ الحجز لا يتغير عند تغير الأسعار المستقبلية.

### Admin

- [ ] لوحة الإدارة مركزية.
- [ ] الإدارة ترى الطلبات.
- [ ] الإدارة تتعامل مع الحجز.
- [ ] الإدارة تتحكم بالمحتوى.
- [ ] الإدارة تتحكم بالغرف.
- [ ] الإدارة تتحكم بالعروض.
- [ ] الإدارة تتحكم بالخدمات.
- [ ] الإدارة تتحكم بالإعدادات.
- [ ] الإدارة تستطيع إخفاء/إظهار/تفعيل/تعطيل ما تسمح به الصلاحيات.
- [ ] كل عملية حساسة مسجلة.

### Communication

- [ ] WhatsApp مرتبط بتدفقات العمل.
- [ ] طلبات التواصل لا تضيع.
- [ ] يمكن ربط التواصل بالحجز.
- [ ] يمكن معرفة المسؤول عن الطلب.
- [ ] توجد حالات واضحة.

### Operations

- [ ] Check-in يعمل.
- [ ] Check-out يعمل.
- [ ] الغرف لها حالات صحيحة.
- [ ] طلبات الخدمات تعمل.
- [ ] المدفوعات تسجل.
- [ ] الفواتير تعمل.

### Content

- [ ] يمكن تعديل النصوص.
- [ ] يمكن تعديل الصور.
- [ ] يمكن إخفاء الأقسام.
- [ ] يمكن تغيير الترتيب.
- [ ] يمكن نشر/إخفاء المحتوى.
- [ ] لا يحتاج ذلك إلى إصدار جديد من التطبيق.

### Security

- [ ] Role Based Access.
- [ ] Permission checks.
- [ ] Audit Logs.
- [ ] Server validation.
- [ ] Secrets protected.
- [ ] Sensitive data protected.

### Quality

- [ ] RTL.
- [ ] Responsive.
- [ ] Adaptive.
- [ ] Loading.
- [ ] Empty.
- [ ] Error.
- [ ] Tests.
- [ ] Performance.

---

# 115. FINAL PRODUCT STATEMENT

هذا المشروع ليس:

> "تطبيق فندق جميل."

وليس:

> "موقعًا للحجز."

وليس:

> "لوحة تحكم مع بعض الصفحات."

بل هو:

> **منصة تشغيل رقمية للفندق، تجعل تجربة العميل بسيطة وسريعة، وتجعل WhatsApp قناة عملية عند الحاجة، وتجعل الإدارة قادرة على رؤية وإدارة والتحكم في دورة العمل كاملة من مكان واحد.**

والقاعدة النهائية التي يجب أن يفهمها أي نموذج ذكاء اصطناعي قبل لمس الكود:

```text
UNDERSTAND THE HOTEL
        ↓
UNDERSTAND THE CUSTOMER
        ↓
UNDERSTAND THE OPERATIONS
        ↓
UNDERSTAND THE COMMUNICATION
        ↓
UNDERSTAND THE BUSINESS RULES
        ↓
DESIGN THE FLOWS
        ↓
DESIGN THE DATA
        ↓
DESIGN THE ADMIN CONTROL
        ↓
BUILD THE BACKEND
        ↓
BUILD THE UI
        ↓
TEST THE COMPLETE BUSINESS JOURNEY
        ↓
DEPLOY
```

> **لا تبدأ بالواجهة.**
>
> **لا تبدأ بالشاشات.**
>
> **لا تبدأ بالكود.**
>
> **ابدأ بفهم العمل، ثم ابنِ النظام الذي يجعل العمل أبسط وأوضح وأقوى.**

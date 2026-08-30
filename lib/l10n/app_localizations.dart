import 'package:flutter/material.dart';

/// Lightweight localization with Arabic + English and full RTL support.
/// (See PLAN §62 — MUST support Arabic RTL.)
class L10n extends ChangeNotifier {
  Locale _locale = const Locale('ar');
  static const Locale arabic = Locale('ar');
  static const Locale english = Locale('en');

  L10n() {
    _locale = const Locale('ar');
  }

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';
  TextDirection get dir => isArabic ? TextDirection.rtl : TextDirection.ltr;

  void setLocale(Locale l) {
    if (_locale == l) return;
    _locale = l;
    notifyListeners();
  }

  void toggle() {
    _locale = isArabic ? english : arabic;
    notifyListeners();
  }

  static L10n of(BuildContext context) {
    final l = context.dependOnInheritedWidgetOfExactType<_L10nScope>();
    return l!.l10n;
  }

  static Widget scope({required L10n l10n, required Widget child}) {
    return _L10nScope(l10n: l10n, child: child);
  }

  // -- Strings --
  String get appName => isArabic ? 'فندق لوميير جراند' : 'Lumière Grand Hotel';
  String get tagline =>
      isArabic ? 'إقامة. خدمة. هدوء.' : 'Stay. Service. Serenity.';

  String get chooseExperience =>
      isArabic ? 'اختر تجربتك' : 'Choose your experience';
  String get chooseExperienceSub => isArabic
      ? 'منصة فندقية متكاملة: موقع الحجز، تطبيق النزيل، الاستقبال، والإدارة'
      : 'One integrated hotel platform: booking site, guest app, reception & admin';
  String get publicWebsite => isArabic ? 'موقع الحجز العام' : 'Public Website';
  String get publicWebsiteSub => isArabic
      ? 'اكتشف الفندق واحجز إقامتك'
      : 'Discover the hotel & book your stay';
  String get guestApp => isArabic ? 'تطبيق النزيل' : 'Guest App';
  String get guestAppSub => isArabic
      ? 'ادخل برمز الدخول الخاص بإقامتك'
      : 'Sign in with your stay access code';
  String get reception => isArabic ? 'الاستقبال (PMS)' : 'Reception (PMS)';
  String get receptionSub =>
      isArabic ? 'عمليات الاستقبال والإقامة' : 'Front-desk & stay operations';
  String get admin => isArabic ? 'الإدارة' : 'Admin';
  String get adminSub =>
      isArabic ? 'إعدادات الفندق والتدقيق' : 'Hotel config & audit';

  String get enter => isArabic ? 'دخول' : 'Enter';
  String get back => isArabic ? 'رجوع' : 'Back';
  String get next => isArabic ? 'التالي' : 'Next';
  String get confirm => isArabic ? 'تأكيد' : 'Confirm';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get save => isArabic ? 'حفظ' : 'Save';
  String get search => isArabic ? 'بحث' : 'Search';
  String get close => isArabic ? 'إغلاق' : 'Close';
  String get home => isArabic ? 'الرئيسية' : 'Home';
  String get rooms => isArabic ? 'الغرف' : 'Rooms';
  String get gallery => isArabic ? 'المعرض' : 'Gallery';
  String get contact => isArabic ? 'تواصل' : 'Contact';
  String get bookNow => isArabic ? 'احجز الآن' : 'Book Now';
  String get checkAvailability =>
      isArabic ? 'تحقق من التوفر' : 'Check Availability';
  String get checkIn => isArabic ? 'تسجيل دخول' : 'Check-In';
  String get checkOut => isArabic ? 'تسجيل مغادرة' : 'Check-Out';
  String get arrivals => isArabic ? 'القادمون' : 'Arrivals';
  String get departures => isArabic ? 'المغادرون' : 'Departures';
  String get inHouse => isArabic ? 'النزلاء الحاليون' : 'In-House';
  String get reservations => isArabic ? 'الحجوزات' : 'Reservations';
  String get requests => isArabic ? 'الطلبات' : 'Requests';
  String get dashboard => isArabic ? 'لوحة العمليات' : 'Dashboard';
  String get roomsBoard => isArabic ? 'لوحة الغرف' : 'Rooms Board';
  String get guests => isArabic ? 'النزلاء' : 'Guests';
  String get billing => isArabic ? 'الفوترة' : 'Billing';
  String get auditLog => isArabic ? 'سجل التدقيق' : 'Audit Log';
  String get myStay => isArabic ? 'إقامتي' : 'My Stay';
  String get myBill => isArabic ? 'فاتورتي' : 'My Bill';
  String get services => isArabic ? 'الخدمات' : 'Services';
  String get receptionChat => isArabic ? 'الاستقبال' : 'Reception';
  String get extendStay => isArabic ? 'تمديد الإقامة' : 'Extend Stay';
  String get roomChange => isArabic ? 'تغيير الغرفة' : 'Room Change';
  String get checkoutRequest => isArabic ? 'طلب المغادرة' : 'Checkout';
  String get notifications => isArabic ? 'الإشعارات' : 'Notifications';
  String get logout => isArabic ? 'خروج' : 'Sign out';
  String get switchSpace => isArabic ? 'تبديل التجربة' : 'Switch experience';
  String get switchLang => isArabic ? 'English' : 'العربية';
  String get switchTheme => isArabic ? 'الوضع الليلي' : 'Dark mode';

  String get enterAccessCode =>
      isArabic ? 'أدخل رمز الدخول للفندق' : 'Enter Hotel Access Code';
  String get accessCodeHint =>
      isArabic ? 'رمز الدخول المكوّن من 6 أرقام' : '6-digit access code';
  String get activate => isArabic ? 'تفعيل' : 'Activate';
  String get invalidCode =>
      isArabic ? 'رمز غير صالح أو منتهي الصلاحية' : 'Invalid or expired code';
  String get demoHint => isArabic
      ? 'للتجربة: استخدم رمز إقامة محمد — 204204'
      : 'Demo: use Mohamed\'s stay code — 204204';

  String get checkInDate => isArabic ? 'تاريخ الوصول' : 'Check-in';
  String get checkOutDate => isArabic ? 'تاريخ المغادرة' : 'Check-out';
  String get adults => isArabic ? 'البالغون' : 'Adults';
  String get children => isArabic ? 'الأطفال' : 'Children';
  String get perNight => isArabic ? '/ليلة' : '/night';
  String get night => isArabic ? 'ليلة' : 'night';
  String get nights => isArabic ? 'ليالي' : 'nights';
  String get total => isArabic ? 'الإجمالي' : 'Total';
  String get subtotal => isArabic ? 'المجموع الفرعي' : 'Subtotal';
  String get taxes => isArabic ? 'الضرائب والرسوم' : 'Taxes & fees';
  String get payNow => isArabic ? 'ادفع الآن' : 'Pay now';
  String get payAtHotel => isArabic ? 'ادفع في الفندق' : 'Pay at hotel';
  String get guestDetails => isArabic ? 'بيانات النزيل' : 'Guest details';
  String get fullName => isArabic ? 'الاسم الكامل' : 'Full name';
  String get email => isArabic ? 'البريد الإلكتروني' : 'Email';
  String get phone => isArabic ? 'الهاتف' : 'Phone';
  String get paymentMethod => isArabic ? 'طريقة الدفع' : 'Payment method';
  String get bookingConfirmed =>
      isArabic ? 'تم تأكيد الحجز' : 'Booking Confirmed';
  String get reservationNo => isArabic ? 'رقم الحجز' : 'Reservation No.';
  String get bookAnother => isArabic ? 'حجز جديد' : 'Book another stay';
  String get selectRoomType =>
      isArabic ? 'اختر نوع الغرفة' : 'Select room type';

  String get welcomeGuest => isArabic ? 'مرحباً' : 'Welcome';
  String get roomLabel => isArabic ? 'الغرفة' : 'Room';
  String get stayUntil => isArabic ? 'حتى' : 'until';
  String get requestService => isArabic ? 'اطلب خدمة' : 'Request a service';
  String get newRequest => isArabic ? 'طلب جديد' : 'New request';
  String get category => isArabic ? 'الفئة' : 'Category';
  String get description => isArabic ? 'الوصف' : 'Description';
  String get sendRequest => isArabic ? 'إرسال الطلب' : 'Send request';
  String get urgent => isArabic ? 'عاجل' : 'Urgent';
  String get noRequestsYet =>
      isArabic ? 'لا توجد طلبات بعد' : 'No requests yet';
  String get markComplete => isArabic ? 'تم الإنجاز' : 'Mark completed';
  String get acknowledge => isArabic ? 'استلام' : 'Acknowledge';
  String get assign => isArabic ? 'إسناد' : 'Assign';
  String get startProgress => isArabic ? 'بدء المعالجة' : 'Start';
  String get requestNo => isArabic ? 'طلب رقم' : 'Request';

  String get outstandingBalance =>
      isArabic ? 'الرصيد المستحق' : 'Outstanding balance';
  String get charges => isArabic ? 'المبالغ المضافة' : 'Charges';
  String get payments => isArabic ? 'المدفوعات' : 'Payments';
  String get addCharge => isArabic ? 'إضافة مبلغ' : 'Add charge';
  String get recordPayment => isArabic ? 'تسجيل دفعة' : 'Record payment';
  String get invoice => isArabic ? 'الفاتورة' : 'Invoice';
  String get paid => isArabic ? 'مدفوع' : 'Paid';
  String get remaining => isArabic ? 'متبقي' : 'Remaining';

  String get assignRoom => isArabic ? 'إسناد غرفة' : 'Assign room';
  String get verifyGuest => isArabic ? 'التحقق من النزيل' : 'Verify guest';
  String get completeCheckIn =>
      isArabic ? 'إتمام تسجيل الدخول' : 'Complete check-in';
  String get accessCodeReady =>
      isArabic ? 'رمز دخول النزيل جاهز' : 'Guest access code is ready';
  String get noArrivals => isArabic ? 'لا قادمون اليوم' : 'No arrivals today';
  String get noDepartures =>
      isArabic ? 'لا مغادرون اليوم' : 'No departures today';
  String get noInHouse => isArabic ? 'لا نزلاء حالياً' : 'No in-house guests';

  String get occupancy => isArabic ? 'نسبة الإشغال' : 'Occupancy';
  String get availableRooms => isArabic ? 'غرف متاحة' : 'Available rooms';
  String get pendingRequests => isArabic ? 'طلبات معلقة' : 'Pending requests';
  String get todaysBookings => isArabic ? 'حجوزات اليوم' : 'Today\'s bookings';

  String get roomTypes => isArabic ? 'أنواع الغرف' : 'Room Types';
  String get servicesCatalog =>
      isArabic ? 'كتالوج الخدمات' : 'Services catalog';
  String get users => isArabic ? 'المستخدمون' : 'Users';
  String get hotelSettings => isArabic ? 'إعدادات الفندق' : 'Hotel settings';
  String get auditTrail =>
      isArabic ? 'سجل العمليات الحساسة' : 'Sensitive operations audit trail';

  String get confirmCheckoutMsg => isArabic
      ? 'سيتم إغلاق الإقامة، تصبح الغرفة بحاجة للتنظيف، ويتعطل وصول النزيل. متابعة؟'
      : 'Stay will close, the room becomes dirty, and guest access is deactivated. Continue?';
  String get yes => isArabic ? 'نعم' : 'Yes';
  String get no => isArabic ? 'لا' : 'No';

  String get optionalNote => isArabic ? 'ملاحظة (اختياري)' : 'Note (optional)';
  String get reason => isArabic ? 'السبب' : 'Reason';
  String get requestExtensionMsg => isArabic
      ? 'سيتم التحقق من التوفر وحساب التكلفة الإضافية ثم مراجعة الاستقبال.'
      : 'Availability will be checked and extra cost calculated, then reception reviews it.';
  String get approved => isArabic ? 'موافق عليه' : 'Approved';
  String get rejected => isArabic ? 'مرفوض' : 'Rejected';
  String get pendingReview => isArabic ? 'قيد المراجعة' : 'Pending review';

  String get allRooms => isArabic ? 'كل الغرف' : 'All rooms';
  String get floor => isArabic ? 'الطابق' : 'Floor';
  String get capacity => isArabic ? 'السعة' : 'Capacity';
  String get bedConfig => isArabic ? 'تجهيز السرير' : 'Bed config';
  String get amenities => isArabic ? 'المرافق' : 'Amenities';
  String get policies => isArabic ? 'السياسات' : 'Policies';

  String get noResults => isArabic ? 'لا توجد نتائج' : 'No results';
  String get loading => isArabic ? 'جارٍ التحميل...' : 'Loading...';
  String get saved => isArabic ? 'تم الحفظ' : 'Saved';
  String get done => isArabic ? 'تم' : 'Done';

  // -- Unified login + staff access codes --
  String get portalLogin => isArabic ? 'تسجيل الدخول' : 'Portal Login';
  String get portalLoginSub => isArabic
      ? 'أدخل رمز الدخول — النظام يحدد تجربتك تلقائياً'
      : 'Enter your access code — the system determines your experience';
  String get accessCode => isArabic ? 'رمز الدخول' : 'Access code';
  String get accessCodeHintUnified => isArabic
      ? 'رمز النزيل (6 أرقام) أو رمز الموظف (ADM-/REC-)'
      : 'Guest code (6 digits) or staff code (ADM-/REC-)';
  String get login => isArabic ? 'دخول' : 'Sign in';
  String get invalidCodeUnified =>
      isArabic ? 'رمز غير صالح أو منتهي الصلاحية' : 'Invalid or expired code';
  String get demoCodes => isArabic
      ? 'للتجربة: نزيل 204204 • استقبال REC-200 • إدارة ADM-100'
      : 'Demo: guest 204204 • reception REC-200 • admin ADM-100';
  String get welcomeGuestShort => isArabic ? 'مرحباً' : 'Welcome';
  String get staffCodes => isArabic ? 'رموز الموظفين' : 'Staff Access Codes';
  String get staffCodesSub => isArabic
      ? 'أنشئ رموز دخول لموظفي الاستقبال والإدارة — يدخلونها في شاشة الدخول'
      : 'Create login codes for reception & admin staff — they enter them at the login screen';
  String get createStaffCode => isArabic ? 'إنشاء رمز جديد' : 'Create code';
  String get staffName => isArabic ? 'اسم الموظف' : 'Staff name';
  String get role => isArabic ? 'الدور' : 'Role';
  String get validityDays =>
      isArabic ? 'مدة الصلاحية (أيام)' : 'Validity (days)';
  String get revoke => isArabic ? 'إلغاء' : 'Revoke';
  String get regenerate => isArabic ? 'تجديد الرمز' : 'Regenerate';
  String get active => isArabic ? 'نشط' : 'Active';
  String get inactive => isArabic ? 'ملغى' : 'Revoked';
  String get lastUsed => isArabic ? 'آخر استخدام' : 'Last used';
  String get never => isArabic ? 'أبداً' : 'Never';
  String get expiresAt => isArabic ? 'تنتهي في' : 'Expires';
  String get codeCreated => isArabic
      ? 'تم إنشاء الرمز ✓ شاركه مع الموظف'
      : 'Code created ✓ share it with the staff member';

  // -- Website pages (PLAN_WEBSITE) --
  String get facilities => isArabic ? 'المرافق' : 'Facilities';
  String get about => isArabic ? 'عن الفندق' : 'About';
  String get location => isArabic ? 'الموقع' : 'Location';
  String get manageBooking => isArabic ? 'إدارة الحجز' : 'Manage Booking';

  // -- App entry (PLAN_MOBILE-APK §5) --
  String get appLoginTitle => isArabic ? 'تسجيل الدخول للتطبيق' : 'App Sign In';
  String get appLoginSub => isArabic
      ? 'أدخل رمز الدخول — الحرف الأول يحدد تجربتك (H=نزيل، R=استقبال، A=إدارة)'
      : 'Enter your access code — the prefix determines your experience (H=Guest, R=Reception, A=Admin)';
  String get demoCodesApp => isArabic
      ? 'للتجربة: نزيل H834729X7 • استقبال R492671M3 • إدارة A371849L9'
      : 'Demo: guest H834729X7 • reception R492671M3 • admin A371849L9';
  String get websiteOnlyCodeWarn => isArabic
      ? 'رموز الحجز (HTL-...) تُستخدم لإدارة الحجز على الموقع فقط، وليس للدخول للتطبيق'
      : 'Booking references (HTL-...) are for website booking management only, not app login';
}

class _L10nScope extends InheritedWidget {
  const _L10nScope({required this.l10n, required super.child});
  final L10n l10n;

  @override
  bool updateShouldNotify(_L10nScope old) => l10n != old.l10n;
}

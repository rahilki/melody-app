# Melody

A new Flutter project created with FlutLab - https://flutlab.io

## Getting Started

A few resources to get you started if this is your first Flutter project:

- https://flutter.dev/docs/get-started/codelab
- https://flutter.dev/docs/cookbook

For help getting started with Flutter, view our
https://flutter.dev/docs, which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Getting Started: FlutLab - Flutter Online IDE

- How to use FlutLab? Please, view our https://flutlab.io/docs
- Join the discussion and conversation on https://flutlab.io/residents

---
# Melody App
# النسخة العربية

## 1. شرح للحل وفكرة المشروع

تطبيق **Melody** مبني بـ Flutter لتسهيل التواصل بين الموسيقيين والعملاء. يمكن للعميل تصفح الفنانين وحجزهم للفعاليات، بينما يستطيع الموسيقي إدارة ملفه الشخصي، إضافة منشورات وأعمال سابقة، واستقبال الحجوزات. كما يوجد وضع الضيف للتصفح بدون تسجيل دخول. يعتمد الحل على **Firebase** لإدارة المصادقة والبيانات، مع دعم ثنائي اللغة (العربية والإنجليزية) وتصميم عصري ومتجاوب.

## 2. شرح موجز لكل خاصية

* **SignInPage (تسجيل الدخول):** خاصية MVP، شبه مكتملة (\~90%).
* **AccountTypePage (اختيار نوع الحساب):** خاصية MVP، مكتملة 100%.
* **SignupClientPage (إنشاء حساب عميل):** خاصية MVP، مكتملة جزئيًا (\~70%).
* **SignupMusicianPage (إنشاء حساب موسيقي):** خاصية MVP، مكتملة جيدًا (\~85%).
* **ForgotPasswordPage (استعادة كلمة المرور):** خاصية MVP، مكتملة 100%.
* **GuestPage (وضع الضيف):** خاصية إضافية، مكتملة 100%.
* **ClientHomePage (الصفحة الرئيسية للعميل):** خاصية MVP، شبه مكتملة (\~80%).
* **ArtistsPage (صفحة الفنانين):** خاصية MVP، شبه مكتملة (\~85%).
* **ArtistPublicPage (بروفايل الفنان العام):** خاصية MVP، شبه مكتملة (\~80%).
* **MusicianProfilePage (بروفايل الموسيقي):** خاصية MVP، تحتاج تطوير أكبر (\~75%).
* **AddPostPage (إضافة منشور):** خاصية إضافية، موجودة لكن تنقصها التكامل مع رفع الوسائط (\~60%).
* **ClientBookingsPage / MusicianBookingsPage (الحجوزات):** خاصية MVP، شبه مكتملة (\~80%).
* **BookingDetailsPage / BookingDetailsViewPage (تفاصيل الحجز):** خاصية MVP، تعمل بشكل أولي (\~70%).
* **RoleHomePage (صفحة التوجيه حسب الدور):** خاصية MVP، مكتملة 100%.
* **AppTheme / GradientButton (الثيم العام والأزرار):** خاصية MVP، مكتملة 100%.

## 3. البنية العليا للحل

* **اللغات:** Dart مع Flutter.
* **خدمات الخلفية:** Firebase Core مفعلة.
* **التخزين والبيانات:**

  * Firebase Authentication لإدارة تسجيل الدخول وإنشاء الحسابات.
  * Firestore لحفظ بيانات المستخدمين، الفنانين، والحجوزات.
  * Firebase Storage لحفظ الصور وعينات الموسيقى (مقترح لخاصية AddPost).
* **اتصالات API خارجية:** لا توجد في النسخة الحالية (مثل LLMs).
* **مدى اكتمال كل مكون:**

  * واجهة Flutter: \~90%
  * Firebase Authentication: 100%
  * Firestore: \~75%
  * Firebase Storage: \~60%

**مخطط مبسط لتدفق البيانات:**

```
واجهة Flutter (شاشات وصفحات)
       │
       ▼
  منطق التطبيق (Routes, State)
       │
       ▼
 خدمات Firebase
 ┌───────────────┐
 │ Authentication│
 │ Firestore     │
 │ Storage       │
 └───────────────┘
```

## 4. البنية التفصيلية للمنطق الداخلي لكل مكون

* **main.dart:** يهيئ Firebase، يحدد لغة التطبيق، وينظم جميع المسارات.
* **theme.dart:** يحتوي الثيم العام، الألوان، والأزرار المخصصة (GradientButton).
* **Authentication (SignIn, Signup, ForgotPassword):** يستخدم FirebaseAuth، وتسجيل الحساب يضيف المستخدم إلى Firestore مع تحديد الدور.
* **AccountTypePage و RoleHomePage:** تحدد مسار المستخدم حسب نوع الحساب وتعيد توجيهه للصفحة المناسبة.
* **ClientHomePage و ArtistsPage:** تعرض قائمة الفنانين وتتيح الوصول إلى بروفايلاتهم العامة.
* **ArtistPublicPage:** تعرض تفاصيل الفنان مع إمكانية بدء عملية الحجز.
* **MusicianProfilePage و AddPostPage:** تسمح للموسيقي بإدارة ملفه ومنشوراته. AddPost متوقع أن يرفع البيانات والصور إلى Firebase Storage.
* **Bookings Pages:** العميل والموسيقي يشاهدان حجوزاتهم عبر استعلام Firestore، ويمكن تعديل الحالة أو الاطلاع على التفاصيل.

---

# English Version

## 1. Description of the Solution

**Melody** is a Flutter-based application that facilitates communication between musicians and clients. Clients can browse artists and book them for events, while musicians can manage their profiles, add posts and past works, and receive bookings. There is also a **Guest mode** for browsing without logging in. The solution relies on **Firebase** for authentication and data management, with bilingual support (Arabic and English) and a modern, responsive design.

## 2. Brief Description of Each Functionality

* **SignInPage (Login):** MVP feature, \~90% complete.
* **AccountTypePage (Account Selection):** MVP feature, 100% complete.
* **SignupClientPage (Create Client Account):** MVP feature, \~70% complete.
* **SignupMusicianPage (Create Musician Account):** MVP feature, \~85% complete.
* **ForgotPasswordPage:** MVP feature, 100% complete.
* **GuestPage:** Additional feature, 100% complete.
* **ClientHomePage:** MVP feature, \~80% complete.
* **ArtistsPage:** MVP feature, \~85% complete.
* **ArtistPublicPage:** MVP feature, \~80% complete.
* **MusicianProfilePage:** MVP feature, \~75% complete.
* **AddPostPage:** Additional feature, \~60% complete; media upload not fully integrated.
* **ClientBookingsPage / MusicianBookingsPage:** MVP feature, \~80% complete.
* **BookingDetailsPage / BookingDetailsViewPage:** MVP feature, \~70% complete.
* **RoleHomePage:** MVP feature, 100% complete.
* **AppTheme / GradientButton:** MVP feature, 100% complete.

## 3. High-Level Architecture

* **Languages:** Dart with Flutter.
* **Backend Services:** Firebase Core enabled.
* **Storage & Data:**

  * Firebase Authentication for login/signup.
  * Firestore for storing users, artists, and bookings.
  * Firebase Storage for images and music samples (proposed for AddPost).
* **External API Connections:** None in current version (e.g., LLMs).
* **Component Completeness:**

  * Flutter UI: \~90%
  * Firebase Authentication: 100%
  * Firestore: \~75%
  * Firebase Storage: \~60%

**Simplified Flow Diagram:**

```
Flutter UI (Screens & Pages)
       │
       ▼
  App Logic (Routes, State)
       │
       ▼
 Firebase Services
 ┌───────────────┐
 │ Authentication│
 │ Firestore     │
 │ Storage       │
 └───────────────┘
```

## 4. Detailed Internal Logic of Each Component

* **main.dart:** Initializes Firebase, sets app language, and organizes routes.
* **theme.dart:** Defines global theme, colors, and custom buttons (GradientButton).
* **Authentication (SignIn, Signup, ForgotPassword):** Uses FirebaseAuth; signup adds user to Firestore with assigned role.
* **AccountTypePage & RoleHomePage:** Determine navigation based on account type.
* **ClientHomePage & ArtistsPage:** Display list of artists and allow access to public profiles.
* **ArtistPublicPage:** Shows artist details and allows booking.
* **MusicianProfilePage & AddPostPage:** Allow musicians to manage profile and posts; AddPost expected to upload data/images to Firebase Storage.
* **Bookings Pages:** Clients and musicians view bookings via Firestore queries; booking status can be updated or viewed in detail pages.

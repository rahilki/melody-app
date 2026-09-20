// اهلا بكم
// سويت هالتطبيق للفنانين و ربطته بالفيربيس
// مناسب للتطبيقات الصغيرة والمتوسطة Auth + Database + Storag جاهز و سريع
// كتبت ملاحضات للرجوع لها وقت الحاجة
// هذا تطبيقي الأول في الفلتر و أعتذر في حالة وجود أخطاء
// نطمح للأفظل
// AND I CAN DO IT
// رحيل البادي

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'theme.dart';
import 'pages/signin_page.dart';
import 'pages/account_type_page.dart';
import 'pages/guest_page.dart';
import 'pages/musician_page.dart';
import 'pages/signup_client_page.dart';
import 'pages/signup_musician_page.dart';
import 'pages/client_home_page.dart';
import 'pages/client_profile_page.dart';
import 'pages/artists_page.dart';
import 'pages/artist_public_page.dart';
import 'pages/musician_profile_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/add_post_page.dart';
import 'pages/booking_details_page.dart';
import 'pages/client_bookings_page.dart';
import 'pages/booking_details_view_page.dart';
import 'pages/musician_bookings_page.dart';
import 'pages/role_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCyL3pt2zPs8bn9s8t3U1UG6QPfcGRJfpQ",
        authDomain: "melodyapp-4efe1.firebaseapp.com",
        projectId: "melodyapp-4efe1",
        storageBucket: "melodyapp-4efe1.appspot.com",
        messagingSenderId: "571847723759",
        appId: "1:571847723759:web:28873a17f8d37b8d7ba91a",
        measurementId: "G-L06F4VJ8YJ",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MelodyApp());
}

class MelodyApp extends StatelessWidget {
  const MelodyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Melody',
        locale: const Locale('ar'),
        supportedLocales: const [
          Locale('ar'),
          Locale('en'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.theme,
        initialRoute: '/signin',
        routes: {
          '/signin': (_) => const SignInPage(),
          '/accountType': (_) => const AccountTypePage(),
          '/guest': (_) => const GuestPage(),
          '/musician': (_) => const MusicianPage(),
          // يفتح الصفحة الرئيسية للعميل
          '/client': (_) => const ClientHomePage(),
          '/signupClient': (_) => const SignupClientPage(),
          '/signupMusician': (_) => const SignupMusicianPage(),
          '/clientProfile': (_) => const ClientProfilePage(),
          '/artists': (_) => const ArtistsPage(),
          '/musicianProfile': (_) => const MusicianProfilePage(),
          '/forgotPassword': (_) => const ForgotPasswordPage(),
          '/addPost': (_) => const AddPostPage(),
          '/artistPublic': (_) =>
              const ArtistPublicPage(), // صفحة بروفايل الفنان العام
          '/bookingDetails': (_) => const BookingDetailsPage(),
          '/clientBookings': (_) => const ClientBookingsPage(),
          '/bookingDetailsView': (context) => const BookingDetailsViewPage(),
          '/musicianBookings': (_) => const MusicianBookingsPage(),
          '/home': (_) => const RoleHomePage(),
          '/musician': (_) => const MusicianPage(),
          '/client': (_) => const ClientHomePage(),
        },
      ),
    );
  }
}

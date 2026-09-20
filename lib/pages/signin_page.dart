import 'package:flutter/material.dart';
import '../theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkSavedRoleForLastEmail(); // لمعرفة إذا المستخدم سبق دخل من قبل
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

// ينقلنا للصفحة حسب الرول
  void _goHomeByRole(String? role) {
    if (!mounted) return;
    if (role == 'musician') {
      Navigator.pushReplacementNamed(context, '/musician');
    } else if (role == 'client') {
      Navigator.pushReplacementNamed(context, '/client');
    } else {
      Navigator.pushReplacementNamed(context, '/accountType');
    }
  }

// يشيك آخر دخول
  Future<void> _checkSavedRoleForLastEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastEmail = prefs.getString('lastEmail'); // lowercase
      if (lastEmail == null) return;
      final role = prefs.getString('role_$lastEmail');
      if (role != null) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _goHomeByRole(role));
      }
    } catch (_) {}
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    final email = _email.text.trim();
    final emailLower = email.toLowerCase();
    String role = '';

    try {
      // 1\ تسجيل الدخول Auth
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _pass.text,
      );

      // 2\ قراءة الدور من Firestore (users)
      final col = FirebaseFirestore.instance.collection('users');
      var snap =
          await col.where('emailLower', isEqualTo: emailLower).limit(1).get();
      if (snap.docs.isEmpty) {
        snap = await col.where('email', isEqualTo: email).limit(1).get();
      }
      if (snap.docs.isNotEmpty) {
        final d = snap.docs.first.data();
        final r = (d['role'] as String?)?.trim().toLowerCase();
        if (r == 'musician') {
          role = 'musician';
        } else if (r == 'client') {
          role = 'client';
        } else {
          role = ''; // أي قيمة غير صحيحة يفتح صفحة اختيار الدور
        }

        // إضافة تخزين userDocId
        try {
          final userDocId = snap.docs.first.id;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userDocId', userDocId);
        } catch (_) {}
      }

      // 3\ نحفظ محليًا
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastEmail', emailLower);
      if (role.isNotEmpty) {
        await prefs.setString('role_$emailLower', role);
      }
      await prefs.remove('role'); // تنظيف القديم

      _goHomeByRole(role);
    } on FirebaseAuthException catch (e) {
      String msg = 'تعذّر تسجيل الدخول.';
      if (e.code == 'user-not-found')
        msg = 'الحساب غير موجود.';
      else if (e.code == 'wrong-password')
        msg = 'كلمة المرور غير صحيحة.';
      else if (e.code == 'invalid-email') msg = 'بريد إلكتروني غير صالح.';
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    } finally {
      if (mounted)
        setState(() => _loading =
            false); // لو المستخدم غادر الصفحة قبل انتهاء العملية → يمنع الخطأ
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
              decoration: BoxDecoration(
                gradient: AppTheme.panelGradient,
                borderRadius: BorderRadius.circular(34),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 20)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 8)
                          ],
                        ),
                        child: TextButton(
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, '/guest'),
                          child: const Text('تخطي',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 8)
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.language,
                                size: 18, color: AppTheme.primaryDark),
                            SizedBox(width: 6),
                            Text('Eng',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // زر الايقونة بدون بوردر
                      IconButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/accountType'),
                        icon: const Icon(Icons.arrow_forward_ios_rounded,
                            color: AppTheme.primaryDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(28), // الحشوة
                      decoration: BoxDecoration(
                        color: AppTheme.mint,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Image.asset(
                        'assets/images/melody.png', // شعارنا ميلودي حبيب قلبي
                        width: 120, // حجم الأيقونة
                        height: 120, // حجم الأيقونة
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Column(
                      children: [
                        Text(
                          'مرحبًا بك في ميلودي',
                          // مرحبتين حبايبي والله :)
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.purpleInk),
                        ),
                        SizedBox(height: 6),
                        Text('حيث تجد كل نغمة موطنها',
                            style: TextStyle(color: Colors.black54))
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.center, // 🔹 النص بالوسط
                          children: [
                            const Text(
                              'تسجيل الدخول',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _email,
                              textAlign: TextAlign.right,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                hintText: 'ادخل بريدك الإلكتروني',
                                prefixIcon: Icon(Icons.alternate_email_rounded),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'البريد مطلوب';
                                final rx =
                                    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                                if (!rx.hasMatch(v.trim()))
                                  return 'صيغة بريد غير صحيحة';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _pass,
                              textAlign: TextAlign.right,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                hintText: 'كلمة المرور',
                                prefixIcon:
                                    const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(_obscure
                                      ? Icons.visibility
                                      : Icons.visibility_off),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'كلمة المرور مطلوبة';
                                if (v.length < 6) return 'الحد الأدنى 6 أحرف';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () => Navigator.pushNamed(
                                    context, '/forgotPassword'),
                                child: const Text('هل نسيت كلمة المرور؟'),
                              ),
                            ),
                            AbsorbPointer(
                              absorbing: _loading,
                              child: Opacity(
                                opacity: _loading ? 0.6 : 1,
                                child: GradientButton(
                                  label: _loading
                                      ? 'جاري الدخول...'
                                      : 'تسجيل الدخول',
                                  icon: Icons.login_rounded,
                                  onPressed: _loading ? null : _login,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GradientButton(
                    label: 'إنشاء حساب',
                    icon: Icons.person_add_alt_1_rounded,
                    gradient: AppTheme.orangeGrad,
                    onPressed: () =>
                        Navigator.pushNamed(context, '/accountType'),
                  ),
                  const SizedBox(height: 18),
                  const Center(
                    child: Text(
                      'يمكنك التصفح كضيف باستخدام زر "تخطي" بالأعلى',
                      style: TextStyle(color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

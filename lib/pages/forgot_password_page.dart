import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    //_prefillEmail();
  }

  Future<void> _prefillEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getString('lastEmail');
      if (last != null && last.isNotEmpty) {
        _email.text = last;
        setState(() {});
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    final email = _email.text.trim();

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إرسال رابط إعادة تعيين كلمة المرور إلى $email'),
        ),
      );

      Navigator.pop(context); // رجوع لصفحة تسجيل الدخول
    } on FirebaseAuthException catch (e) {
      String msg = 'تعذّر إرسال الرابط. جرّب لاحقًا.';
      if (e.code == 'user-not-found') {
        msg = 'لا يوجد حساب بهذا البريد.';
      } else if (e.code == 'invalid-email') {
        msg = 'صيغة البريد غير صحيحة.';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ غير متوقع.')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إعادة تعيين كلمة المرور')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const Text(
                  'أدخل بريدك الإلكتروني المسجّل وسنرسل لك رابطًا لإعادة تعيين كلمة المرور.',
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                      const InputDecoration(labelText: 'البريد الإلكتروني'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'مطلوب';
                    final rx = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!rx.hasMatch(v.trim())) return 'صيغة غير صحيحة';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _sendReset,
                    child: _sending
                        ? const CircularProgressIndicator()
                        : const Text('إرسال رابط إعادة التعيين'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

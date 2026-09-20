import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupMusicianPage extends StatefulWidget {
  const SignupMusicianPage({super.key});

  @override
  State<SignupMusicianPage> createState() => _SignupMusicianPageState();
}

class _SignupMusicianPageState extends State<SignupMusicianPage> {
  final _formKey = GlobalKey<FormState>();

  final _fullName = TextEditingController();
  final _stageName = TextEditingController();
  final _mainInstrument = TextEditingController();
  final _genre = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _social = TextEditingController(); // اختياري
  final _password = TextEditingController();

  bool _obscure = true; // للتحكم في إظهار/إخفاء كلمة المرور

  @override
  void dispose() {
    _fullName.dispose();
    _stageName.dispose();
    _mainInstrument.dispose();
    _genre.dispose();
    _email.dispose();
    _phone.dispose();
    _social.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _email.text.trim();
    final emailLower = email.toLowerCase();
    final password = _password.text.trim();

    try {
      // 1) إنشاء مستخدم في Firebase Auth
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // 2) حفظ بيانات المستخدم في Firestore
      final col = FirebaseFirestore.instance.collection('users');
      final data = {
        'fullName': _fullName.text.trim(),
        'stageName': _stageName.text.trim(),
        'mainInstrument': _mainInstrument.text.trim(),
        'genre': _genre.text.trim(),
        'email': email,
        'emailLower': emailLower,
        'phone': _phone.text.trim(),
        'social': _social.text.trim(),
        'role': 'musician',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await col.doc(cred.user!.uid).set(data);

      // 3) تخزين بيانات في SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastEmail', emailLower);
      await prefs.setString('role_$emailLower', 'musician');
      await prefs.setString('userDocId', cred.user!.uid);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/musician');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل موسيقي')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _fullName,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stageName,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(labelText: 'الاسم الفني'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mainInstrument,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                    labelText: 'الآلة الرئيسية (مثال: غيتار)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _genre,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                    labelText: 'الأسلوب/النوع (مثال: كلاسيك)'),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                textAlign: TextAlign.right,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                validator: (v) =>
                    (v == null || v.trim().length < 8) ? 'رقم غير صحيح' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _social,
                textAlign: TextAlign.right,
                decoration:
                    const InputDecoration(labelText: 'رابط السوشيال (اختياري)'),
              ),
              const SizedBox(height: 12),
              // كلمة المرور
              TextFormField(
                controller: _password,
                textAlign: TextAlign.right,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscure = !_obscure;
                      });
                    },
                  ),
                ),
                validator: (v) => (v == null || v.trim().length < 6)
                    ? 'الحد الأدنى 6 أحرف'
                    : null,
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                  onPressed: _submit, child: const Text('إنشاء الحساب')),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupClientPage extends StatefulWidget {
  const SignupClientPage({super.key});

  @override
  State<SignupClientPage> createState() => _SignupClientPageState();
}

class _SignupClientPageState extends State<SignupClientPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _companyName = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _companyName.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    final email = _email.text.trim();
    final emailLower = email.toLowerCase();

    try {
      // 1/ إنشاء حساب Auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: _password.text,
      );
      final user = cred.user!;
      final uid = user.uid;

      // 2/ كتابة وثيقة المستخدم في users/{uid}
      final data = {
        'name': _name.text.trim(),
        'companyName': _companyName.text.trim(),
        'email': email,
        'emailLower': emailLower,
        'phone': _phone.text.trim(),
        'role': 'client',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(data, SetOptions(merge: true));

      // 3/ تخزين محلي للتوجيه لاحقاً
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastEmail', emailLower);
      await prefs.setString('role_$emailLower', 'client');
      await prefs.setString('userDocId', uid);
      await prefs.remove('role'); // تنظيف مفتاح قديم

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/client', (_) => false);
    } on FirebaseAuthException catch (e) {
      String msg = 'تعذّر إنشاء الحساب.';
      if (e.code == 'email-already-in-use') msg = 'البريد مستخدم مسبقًا.';
      if (e.code == 'weak-password') msg = 'كلمة المرور ضعيفة.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firestore: ${e.code} - ${e.message}')),
      );
    } catch (e) {
      // في حال صار خطأ يتخزن في e
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('خطأ: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل عميل')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _name,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(labelText: 'الاسم'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _companyName,
                textAlign: TextAlign.right,
                decoration:
                    const InputDecoration(labelText: 'اسم الشركة (اختياري)'),
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
                controller: _password,
                textAlign: TextAlign.right,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'كلمة المرور'),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'كلمة مرور قصيرة' : null,
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: Text(_loading ? 'جاري الإنشاء...' : 'إنشاء الحساب'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

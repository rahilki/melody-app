import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class AccountTypePage extends StatelessWidget {
  const AccountTypePage({super.key});

  Future<void> _chooseRole(BuildContext context, String role) async {
    // نحفظ الرولز المختار من المستخدم
    // SharedPreferences عشان نحفظ آخر تسجيل دخول يعني المستخدم ما يضطر يسجل دخول مرة ثانية
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role);
    //نخزن الرول

    // نوجّه لصفحة التسجيل المناسبة
    // صفحة الضيف ناقصة
    if (!context.mounted) return;
    if (role == 'musician') {
      Navigator.pushNamed(context, '/signupMusician');
    } else {
      Navigator.pushNamed(context, '/signupClient');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر نوع حسابك'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.pushReplacementNamed(
                context, '/signin'); // رجوع للصفحة الرئيسية
          },
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.mint,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.person,
                    size: 36, color: AppTheme.primaryDark),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'اختر نوع حسابك',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'حدد كيف تريد استخدام ميلودي',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),

            // كرت: موسيقي
            _roleCard(
              title: 'موسيقي',
              subtitle: 'اعرض موهبتك وتواصل مع الفرص',
              icon: Icons.music_note,
              onTap: () => _chooseRole(context, 'musician'),
            ),

            // كرت: عميل
            _roleCard(
              title: 'عميل',
              subtitle: 'ابحث عن الموسيقيين ونظم الفعاليات',
              icon: Icons.groups_rounded,
              onTap: () => _chooseRole(context, 'client'),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _roleCard({
  required String title,
  required String subtitle,
  required IconData icon,
  required VoidCallback onTap,
}) {
  // اللون حسب نوع الحساب
  Color bgColor =
      (title == 'موسيقي') ? Colors.purple.shade50 : Colors.orange.shade50;
  Color iconColor = (title == 'موسيقي') ? Colors.purple : Colors.orange;

  return Card(
    color: bgColor,
    elevation: 1.5,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: bgColor,
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: iconColor,
        ),
      ),
      subtitle: Text(subtitle, textAlign: TextAlign.right),
      trailing: Icon(Icons.arrow_forward_ios, color: iconColor), // سهم يمين
      onTap: onTap,
    ),
  );
}

//رحيل البادي

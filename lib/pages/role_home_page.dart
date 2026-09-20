import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoleHomePage extends StatefulWidget {
  const RoleHomePage({super.key});

  @override
  State<RoleHomePage> createState() => _RoleHomePageState();
}

class _RoleHomePageState extends State<RoleHomePage> {
  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    final prefs = await SharedPreferences.getInstance();
    final lastEmail = prefs.getString('lastEmail'); // lowercase
    final role =
        (lastEmail == null) ? null : prefs.getString('role_$lastEmail');

// توجيه حسب الرول
    if (!mounted) return;
    if (role == 'musician') {
      Navigator.pushReplacementNamed(context, '/musician');
    } else if (role == 'client') {
      Navigator.pushReplacementNamed(context, '/client');
    } else {
      Navigator.pushReplacementNamed(context, '/accountType');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

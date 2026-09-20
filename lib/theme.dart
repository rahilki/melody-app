// صفحة الثيم مال التطبيق

import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF2EC4F6);
  static const Color primaryDark = Color(0xFF1891C9);
  static const Color mint = Color(0xFFD6F5F8);
  static const Color purpleInk = Color(0xFF5E46A1);
  static const Color accentOrange = Color(0xFFFFA45B);

  static const LinearGradient panelGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE9FBFF), Color(0xFFD4F5FF), Color(0xFFC9F0FF)],
  );

  static const LinearGradient btnGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF33D1FF), Color(0xFF1AB3E6)],
  );

  static const LinearGradient orangeGrad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFBE88), Color(0xFFFFA45B)],
  );

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Tajawal', // خط التطبيق
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accentOrange,
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor:
          const Color(0xFFF4F7FB), // لون الخلفية الرئيسي للشاشات
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: purpleInk,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        elevation: 10,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      // كل الكروت بتكون بحواف دائرية وظل خفيف
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: const Color(0xFF263238),
        displayColor: const Color(0xFF263238),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final IconData? icon;
  final bool fullWidth;
  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.gradient,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: gradient ?? AppTheme.btnGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) Icon(icon, color: Colors.white),
          if (icon != null) const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );

    return InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: child);
  }
}

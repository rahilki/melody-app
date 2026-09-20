import 'package:flutter/material.dart';

class GuestPage extends StatelessWidget {
  const GuestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التصفح كضيف')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            'مرحبًا! أنت الآن تتصفح كتجربة ضيف (MVP).',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          Text(
            'لاحقًا سنعرض: قائمة موسيقيين للتجربة، وبطاقات تعريف مبسطة.',
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}

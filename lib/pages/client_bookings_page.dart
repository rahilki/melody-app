import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ClientBookingsPage extends StatelessWidget {
  const ClientBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('يرجى تسجيل الدخول.')),
      );
    }

    final query = FirebaseFirestore.instance
        .collection('bookings')
        .where('clientAuthUid', isEqualTo: uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('حجوزاتي'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded), // يسار
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFFF5F7FB),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('حدث خطأ: ${snap.error}'));
          }
          final data = snap.data;
          if (data == null || data.docs.isEmpty) {
            return const Center(child: Text('لا توجد حجوزات بعد.'));
          }

          // ترتيب محلي حسب createdAt تنازليًا
          final docs = [...data.docs]..sort((a, b) {
              final ta = a.data()['createdAt'];
              final tb = b.data()['createdAt'];
              final da = ta is Timestamp
                  ? ta.toDate()
                  : DateTime.fromMillisecondsSinceEpoch(0);
              final db = tb is Timestamp
                  ? tb.toDate()
                  : DateTime.fromMillisecondsSinceEpoch(0);
              return db.compareTo(da);
            });

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final id = docs[i].id;

              final musicianName = (d['musicianName'] ?? 'فنان').toString();
              final status = (d['status'] ?? '').toString();
              final ts = d['eventDate'];
              final eventDate = ts is Timestamp ? ts.toDate().toLocal() : null;

              return Card(
                color: Colors.orange.shade50, // برتقالي أفتح
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    musicianName,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(height: 4),
                      if (eventDate != null)
                        Text('تاريخ المناسبة: ${_fmtDateTime(eventDate)}',
                            textAlign: TextAlign.right),
                      const SizedBox(height: 6),
                      _StatusPill(text: status),
                    ],
                  ),
                  trailing:
                      const Icon(Icons.chevron_right_rounded), // السهم يمين
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/bookingDetailsView',
                      arguments: {
                        'bookingId': id,
                        'id': id,
                        'docId': id,
                        'booking': {'id': id, ...d},
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _fmtDateTime(DateTime d) {
    final yyyy = d.year.toString().padLeft(4, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dd-$mm-$yyyy  $hh:$min';
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  const _StatusPill({required this.text});

  Color _bg() {
    final t = text.trim();
    if (t == 'مرفوض') return const Color(0xFFFFE8E8);
    if (t == 'مقبول') return const Color(0xFFE9FFF0);
    return const Color(0xFFEFF3FF);
  }

  Color _fg() {
    final t = text.trim();
    if (t == 'مرفوض') return const Color(0xFFD12B2B);
    if (t == 'مقبول') return const Color(0xFF1F8B4C);
    return const Color(0xFF3A4DB7);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: _bg(), borderRadius: BorderRadius.circular(999)),
        child: Text(text.isEmpty ? 'قيد المراجعة' : text,
            style: TextStyle(fontWeight: FontWeight.w700, color: _fg())),
      ),
    );
  }
}

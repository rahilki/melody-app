import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingDetailsViewPage extends StatefulWidget {
  const BookingDetailsViewPage({super.key});

  @override
  State<BookingDetailsViewPage> createState() => _BookingDetailsViewPageState();
}

class _BookingDetailsViewPageState extends State<BookingDetailsViewPage> {
  bool _working = false;

  // نخزّن userDocId للمستخدم الحالي للتحقق من ملكية الحجز من جهة الفنان (docId)
  String? _myUserDocId;

  @override
  void initState() {
    super.initState();
    _loadMyDocId();
  }

  Future<void> _loadMyDocId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _myUserDocId = prefs.getString('userDocId');
    });
  }

  String _fmtDT(Timestamp? ts) {
    if (ts == null) return '—';
    final dt = ts.toDate().toLocal();
    final d =
        '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final t =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d $t';
  }

  // إلغاء من جهة العميل
  Future<void> _cancelBooking(String id) async {
    setState(() => _working = true);
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(id).update({
        'status': 'ملغي',
        'canceledBy': 'client',
        'canceledAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إلغاء الحجز')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر الإلغاء: $e')),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  // تحديث الحالة من جهة الفنان
  Future<void> _updateBookingStatus(String id, String nextStatus) async {
    setState(() => _working = true);
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(id).update({
        'status': nextStatus, // 'مقبول' أو 'مرفوض'
        'decisionBy': 'musician',
        'decisionAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث الحالة إلى "$nextStatus"')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التحديث: $e')),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _acceptBooking(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد القبول'),
        content: const Text('سيتم تغيير الحالة إلى "مقبول". هل تريد المتابعة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('لا')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('نعم، قبول')),
        ],
      ),
    );
    if (ok == true) await _updateBookingStatus(id, 'مقبول');
  }

  Future<void> _rejectBooking(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الرفض'),
        content: const Text('سيتم تغيير الحالة إلى "مرفوض". هل تريد المتابعة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('لا')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('نعم، رفض')),
        ],
      ),
    );
    if (ok == true) await _updateBookingStatus(id, 'مرفوض');
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    String? id = args?['id'] as String?;
    id ??= args?['bookingId'] as String?;
    id ??= args?['docId'] as String?;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل الحجز'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: (id == null)
            ? const Center(child: Text('لم يتم تمرير رقم الحجز.'))
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(id)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snap.hasData || !snap.data!.exists) {
                    return const Center(child: Text('الحجز غير موجود.'));
                  }

                  final d = snap.data!.data()!;
                  final currentUid = FirebaseAuth.instance.currentUser?.uid;

                  // العميل (مالك الحجز)
                  final ownerUid = (d['clientAuthUid'] ?? '').toString();
                  final isOwner = currentUid != null && currentUid == ownerUid;

                  // الفنان (docId للفنان كما يُحفظ في الحجز)
                  final musicianId = (d['musicianId'] ?? '').toString();

                  // تمييز إذا كان المستخدم الحالي هو الفنان المعني بالحجز
                  final bool isMusician =
                      (currentUid != null && currentUid == musicianId) ||
                          (_myUserDocId != null && _myUserDocId == musicianId);

                  final musicianName = (d['musicianName'] ?? 'فنان').toString();
                  final clientName = (d['clientName'] ?? 'عميل').toString();
                  final status = (d['status'] ?? 'قيد المراجعة').toString();
                  final eventTs = d['eventDate'] as Timestamp?;
                  final createdTs = d['createdAt'] as Timestamp?;
                  final notes = (d['notes'] ?? '').toString();

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // معلومات أساسية
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _row('الفنان', musicianName, Icons.mic_rounded),
                              const SizedBox(height: 10),
                              _row('العميل', clientName, Icons.person_rounded),
                              const SizedBox(height: 10),
                              _row('الحالة', status, Icons.info_rounded,
                                  bold: true),
                              const SizedBox(height: 10),
                              _row('تاريخ المناسبة', _fmtDT(eventTs),
                                  Icons.event_rounded),
                              const SizedBox(height: 10),
                              _row('تاريخ الإنشاء', _fmtDT(createdTs),
                                  Icons.calendar_today_rounded),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // الملاحظات
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('الملاحظات',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Text(notes.isEmpty ? '—' : notes,
                                  textAlign: TextAlign.right),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // أزرار الإجراءات بحسب الدور والحالة
                      if (isMusician && status == 'قيد المراجعة') ...[
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed:
                                    _working ? null : () => _acceptBooking(id!),
                                icon: _working
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : const Icon(Icons.check_circle),
                                label:
                                    Text(_working ? 'جارٍ التنفيذ...' : 'قبول'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red),
                                onPressed:
                                    _working ? null : () => _rejectBooking(id!),
                                icon: _working
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : const Icon(Icons.highlight_off_rounded),
                                label:
                                    Text(_working ? 'جارٍ التنفيذ...' : 'رفض'),
                              ),
                            ),
                          ],
                        ),
                      ] else if (isOwner && status != 'ملغي') ...[
                        SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            icon: _working
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.cancel),
                            style: FilledButton.styleFrom(
                                backgroundColor: Colors.red),
                            label: Text(
                                _working ? 'جارٍ الإلغاء...' : 'إلغاء الحجز'),
                            onPressed: _working
                                ? null
                                : () async {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('تأكيد الإلغاء'),
                                        content: const Text(
                                            'سيتم تغيير حالة الحجز إلى "ملغي". تريد المتابعة؟'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('لا')),
                                          ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text('نعم، إلغاء')),
                                        ],
                                      ),
                                    );
                                    if (ok == true) {
                                      await _cancelBooking(id!);
                                    }
                                  },
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _row(String title, String value, IconData icon, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

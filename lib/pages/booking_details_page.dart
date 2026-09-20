import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingDetailsPage extends StatefulWidget {
  const BookingDetailsPage(
      {super.key}); //StatefulWidget لأن الصفحة فيها حالة متغيرة

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

// بيانات العميل و الفنان
class _BookingDetailsPageState extends State<BookingDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  bool _saving = false;

  String? _clientDocId;
  String? _clientName;
  String? _clientEmailLower;

  String? _musicianId;
  String? _musicianName;

  @override
  void initState() {
    super.initState();
    _loadClient();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadClient() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('userDocId');
      DocumentSnapshot<Map<String, dynamic>>? userDoc;

      if (savedId != null) {
        final d = await FirebaseFirestore.instance
            .collection('users')
            .doc(savedId)
            .get();
        if (d.exists) userDoc = d;
      }

      if (userDoc == null) {
        final authUser = FirebaseAuth.instance.currentUser;
        if (authUser != null) {
          final email = authUser.email;
          final emailLower = email?.toLowerCase().trim();

          if (emailLower != null) {
            final q1 = await FirebaseFirestore.instance
                .collection('users')
                .where('emailLower', isEqualTo: emailLower)
                .limit(1)
                .get();
            if (q1.docs.isNotEmpty) userDoc = q1.docs.first;
          }

          if (userDoc == null && email != null) {
            final q2 = await FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: email)
                .limit(1)
                .get();
            if (q2.docs.isNotEmpty) userDoc = q2.docs.first;
          }
        }
      }

      if (userDoc == null || !userDoc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('تعذّر تحديد حساب العميل. يرجى تسجيل الدخول من جديد.')),
        );
        return;
      }

      final data = userDoc.data()!;
      setState(() {
        _clientDocId = userDoc!.id;
        _clientName = (data['name'] ?? data['fullName'] ?? '').toString();
        final fromDocLower = (data['emailLower'] ?? '').toString();
        _clientEmailLower = fromDocLower.isNotEmpty
            ? fromDocLower
            : (data['email'] is String
                ? (data['email'] as String).toLowerCase().trim()
                : null);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل حساب العميل: $e')),
      );
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      initialDate: _date ?? now,
      locale: const Locale('ar'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
      builder: (ctx, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
    );
    if (picked != null) setState(() => _time = picked);
  }

  DateTime? get _combinedDateTime {
    if (_date == null || _time == null) return null;
    return DateTime(
        _date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
  }

  Future<void> _saveBooking() async {
    if (_musicianId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'لم يتم تحديد الفنان. ارجع للصفحة السابقة ثم حاول مجددًا.')),
      );
      return;
    }
    if (_clientDocId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تعذّر تحديد حساب العميل. يرجى تسجيل الدخول.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final dt = _combinedDateTime; // اذا الوقت و التاريخ فاضي
    if (dt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار التاريخ والوقت.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول قبل إرسال الحجز.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('bookings').add({
        'clientAuthUid': user.uid, // يطابق القواعد
        'clientId': _clientDocId, // docId للعميل
        'clientName': _clientName,
        'clientEmailLower': _clientEmailLower,
        'musicianId': _musicianId, // يبقى docId للفنان
        'musicianName': _musicianName,
        'musicianAuthUid': _musicianId,
        'eventDate': Timestamp.fromDate(dt),
        'notes': _notes.text.trim(),
        'status': 'قيد المراجعة',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم إرسال طلب الحجز بنجاح (قيد المراجعة).')),
      );
      Navigator.pushReplacementNamed(context, '/clientBookings');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر حفظ الحجز: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

// يقرأ بيانات الفنان اللي جاية من الصفحة السابقة
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    _musicianId ??= args?['musicianId'] as String?;
    _musicianName ??= args?['musicianName'] as String?;

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
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                if (_musicianName != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(_musicianName!),
                      subtitle: const Text('الفنان المطلوب',
                          textAlign: TextAlign.right),
                    ),
                  ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(
                    _date == null
                        ? 'اختر التاريخ'
                        : '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}',
                  ),
                  trailing: TextButton(
                    onPressed: _pickDate,
                    child: const Text('تحديد التاريخ'),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(
                    _time == null
                        ? 'اختر الوقت'
                        : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}',
                  ),
                  trailing: TextButton(
                    onPressed: _pickTime,
                    child: const Text('تحديد الوقت'),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (_) => null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check),
                    label: Text(_saving ? 'جارٍ الحفظ...' : 'تأكيد الحجز'),
                    onPressed: _saving ? null : _saveBooking,
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

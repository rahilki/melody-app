import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class ClientProfilePage extends StatefulWidget {
  const ClientProfilePage({super.key});

  @override
  State<ClientProfilePage> createState() => _ClientProfilePageState();
}

class _ClientProfilePageState extends State<ClientProfilePage> {
  bool _loading = true;
  String? _docId;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final emailLower = prefs.getString('lastEmail');
      if (emailLower == null) {
        setState(() => _loading = false);
        return;
      }
      final col = FirebaseFirestore.instance.collection('users');
      var snap =
          await col.where('emailLower', isEqualTo: emailLower).limit(1).get();
      if (snap.docs.isEmpty) {
        snap = await col.where('email', isEqualTo: emailLower).limit(1).get();
      }
      if (snap.docs.isNotEmpty) {
        _docId = snap.docs.first.id;
        _data = snap.docs.first.data();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveEdits({
    required String name,
    required String phone,
    required String company,
  }) async {
    if (_docId == null) return;
    await FirebaseFirestore.instance.collection('users').doc(_docId).set({
      'name': name,
      'phone': phone,
      'companyName': company,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تحديث البيانات بنجاح')),
    );
  }

  void _openEditSheet() {
    if (_data == null) return;
    final name = TextEditingController(text: (_data!['name'] ?? '').toString());
    final phone =
        TextEditingController(text: (_data!['phone'] ?? '').toString());
    final company =
        TextEditingController(text: (_data!['companyName'] ?? '').toString());
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('تعديل البيانات',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: name,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'الاسم'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: phone,
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                  validator: (v) => (v == null || v.trim().length < 8)
                      ? 'رقم غير صحيح'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: company,
                  textAlign: TextAlign.right,
                  decoration:
                      const InputDecoration(labelText: 'اسم الشركة (اختياري)'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (!(formKey.currentState?.validate() ?? false))
                            return;
                          Navigator.pop(ctx);
                          _saveEdits(
                            name: name.text.trim(),
                            phone: phone.text.trim(),
                            company: company.text.trim(),
                          );
                        },
                        child: const Text('حفظ'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(value.isEmpty ? '-' : value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: AppTheme.purpleInk),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    final lastEmail = prefs.getString('lastEmail');
    if (lastEmail != null) await prefs.remove('role_$lastEmail');
    await prefs.remove('lastEmail');
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppTheme.purpleInk,
          fontWeight: FontWeight.w900,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Melody'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded), // back (left)
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F7FB),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_data == null)
              ? const Center(child: Text('لم يتم العثور على بيانات الحساب.'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  children: [
                    // كارد برتقالي فاتح
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10)
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFFECEBFF),
                            child: Text(
                              (_data!['name'] ?? 'M').toString().isNotEmpty
                                  ? _data!['name']
                                      .toString()
                                      .characters
                                      .first
                                      .toUpperCase()
                                  : 'M',
                              style: const TextStyle(
                                  color: AppTheme.purpleInk,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text((_data!['name'] ?? '').toString(),
                                    textAlign: TextAlign.right,
                                    style: titleStyle),
                                const SizedBox(height: 4),
                                Text((_data!['email'] ?? '').toString(),
                                    textAlign: TextAlign.right,
                                    style:
                                        const TextStyle(color: Colors.black54)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _infoTile(Icons.business_rounded, 'اسم الشركة',
                        (_data!['companyName'] ?? '').toString()),
                    _infoTile(Icons.phone_rounded, 'رقم الهاتف',
                        (_data!['phone'] ?? '').toString()),
                    _infoTile(Icons.badge_rounded, 'الدور',
                        (_data!['role'] ?? '').toString()),
                    _infoTile(
                        Icons.calendar_today_rounded,
                        'تاريخ الإنشاء',
                        _data!['createdAt'] is Timestamp
                            ? (_data!['createdAt'] as Timestamp)
                                .toDate()
                                .toLocal()
                                .toString()
                            : ''),

                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.event_available_rounded),
                            label: const Text('الحجوزات'),
                            onPressed: () =>
                                Navigator.pushNamed(context, '/clientBookings'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text('تعديل البيانات'),
                            onPressed: _openEditSheet,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }
}

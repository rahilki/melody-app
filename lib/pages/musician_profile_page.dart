import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';

class MusicianProfilePage extends StatefulWidget {
  const MusicianProfilePage({super.key});

  @override
  State<MusicianProfilePage> createState() => _MusicianProfilePageState();
}

class _MusicianProfilePageState extends State<MusicianProfilePage> {
  bool _loading = true;
  String? _docId;
  Map<String, dynamic>? _data;
  String _emailLower = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final users = FirebaseFirestore.instance.collection('users');
      final savedId = prefs.getString('userDocId');
      if (savedId != null && savedId.isNotEmpty) {
        final d = await users.doc(savedId).get();
        if (d.exists) {
          _docId = d.id;
          _data = d.data();
          _emailLower = ((_data?['emailLower'] ?? _data?['email']) ?? '')
              .toString()
              .toLowerCase();
          if (mounted) setState(() => _loading = false);
          return;
        }
      }
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) {
        final d = await users.doc(uid).get();
        if (d.exists) {
          _docId = d.id;
          _data = d.data();
          await prefs.setString('userDocId', _docId!);
          _emailLower = ((_data?['emailLower'] ?? _data?['email']) ?? '')
              .toString()
              .toLowerCase();
          if (mounted) setState(() => _loading = false);
          return;
        }
      }
      final lastLowerPref = prefs.getString('lastEmail');
      if (lastLowerPref != null && lastLowerPref.isNotEmpty) {
        var q = await users
            .where('emailLower', isEqualTo: lastLowerPref)
            .limit(1)
            .get();
        if (q.docs.isEmpty) {
          q = await users
              .where('email', isEqualTo: lastLowerPref)
              .limit(1)
              .get();
        }
        if (q.docs.isNotEmpty) {
          final doc = q.docs.first;
          _docId = doc.id;
          _data = doc.data();
          await prefs.setString('userDocId', _docId!);
          _emailLower = (lastLowerPref).toLowerCase();
          if (mounted) setState(() => _loading = false);
          return;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString('lastEmail');
    if (last != null) await prefs.remove('role_$last');
    await prefs.remove('lastEmail');
    await prefs.remove('userDocId');
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (_) => false);
  }

  // ====== فتح نافذة التعديل ======
  void _openEditSheet() {
    if (_data == null) return;
    final stageName =
        TextEditingController(text: (_data!['stageName'] ?? '').toString());
    final fullName =
        TextEditingController(text: (_data!['fullName'] ?? '').toString());
    final phone =
        TextEditingController(text: (_data!['phone'] ?? '').toString());
    final instrument = TextEditingController(
        text: (_data!['mainInstrument'] ?? '').toString());
    final social =
        TextEditingController(text: (_data!['social'] ?? '').toString());
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
                const Text('تعديل بيانات الفنان',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: stageName,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'الاسم الفني'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: fullName,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: instrument,
                  textAlign: TextAlign.right,
                  decoration:
                      const InputDecoration(labelText: 'الآلة الرئيسية'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: phone,
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: social,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                      labelText: 'السوشال/روابط (اختياري)'),
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
                        onPressed: () async {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          Navigator.pop(ctx);
                          if (_docId != null) {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(_docId)
                                .set({
                              'stageName': stageName.text.trim(),
                              'fullName': fullName.text.trim(),
                              'mainInstrument': instrument.text.trim(),
                              'phone': phone.text.trim(),
                              'social': social.text.trim(),
                              'updatedAt': FieldValue.serverTimestamp(),
                            }, SetOptions(merge: true));
                            await _load();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('تم تحديث البيانات')),
                            );
                          }
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

  // ====== صلاحية حذف المنشور ======
  bool _canDeletePost(Map<String, dynamic> d) {
    final curUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final authorId = (d['authorId'] ?? '').toString();
    final authorUid = (d['authorUid'] ?? '').toString();
    return (_docId != null && authorId == _docId) ||
        (curUid.isNotEmpty && authorUid == curUid);
  }

  Future<void> _confirmDelete(String postId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف المنشور'),
          content:
              const Text('هل أنت متأكد من حذف هذا المنشور؟ لا يمكن التراجع.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء')),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.delete_forever),
              label: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
    }
  }

  Widget _row(String label, String value, IconData icon) {
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

  // ====== بطاقة منشور ======
  Widget _postCard(DocumentSnapshot<Map<String, dynamic>> e) {
    final d = e.data()!;
    final postId = e.id;
    final title = (d['title'] ?? '').toString();
    final text = (d['text'] ?? d['content'] ?? '').toString();
    final imageUrl = (d['imageUrl'] ?? '').toString();
    final created = d['createdAt'] is Timestamp
        ? (d['createdAt'] as Timestamp).toDate().toLocal()
        : null;

    final canDelete = _canDeletePost(d);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              if (canDelete)
                IconButton(
                  tooltip: 'حذف المنشور',
                  icon:
                      const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _confirmDelete(postId),
                ),
              const Spacer(),
            ],
          ),
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Text(title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          if (text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(text, textAlign: TextAlign.right),
            ),
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(imageUrl, fit: BoxFit.cover),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                if (created != null)
                  Text(
                    created.toString().split('.').first,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                const Spacer(),
                const Icon(Icons.favorite_border_rounded, size: 18),
                const SizedBox(width: 16),
                const Icon(Icons.ios_share_rounded, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerStyle = const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w900,
      fontSize: 18,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Melody'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
          IconButton(
            tooltip: 'الحجوزات',
            icon: const Icon(Icons.event_available_rounded),
            onPressed: () => Navigator.pushNamed(
                context, '/musicianBookings'), // ✅ تعديل هنا
          ),
          IconButton(
            tooltip: 'تعديل',
            icon: const Icon(Icons.edit_rounded),
            onPressed: _openEditSheet, // ✅ تعديل هنا
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F7FB),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_data == null)
              ? const Center(child: Text('تعذّر تحميل البيانات'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  children: [
                    // ✅ هيدر بنفسجي
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7F57FF), Color(0xFF9D84FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 10)
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white24,
                            backgroundImage:
                                (_data!['photoUrl'] ?? '').toString().isNotEmpty
                                    ? NetworkImage(
                                        (_data!['photoUrl'] ?? '').toString())
                                    : null,
                            child: ((_data!['photoUrl'] ?? '')
                                    .toString()
                                    .isEmpty)
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  ((_data!['stageName'] ??
                                          _data!['fullName'] ??
                                          _data!['name'] ??
                                          ''))
                                      .toString(),
                                  textAlign: TextAlign.right,
                                  style: headerStyle,
                                ),
                                const SizedBox(height: 4),
                                Text(((_data!['email']) ?? '').toString(),
                                    textAlign: TextAlign.right,
                                    style:
                                        const TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _row('الاسم الفني', (_data!['stageName'] ?? '').toString(),
                        Icons.mic_rounded),
                    _row('الاسم الكامل', (_data!['fullName'] ?? '').toString(),
                        Icons.badge_rounded),
                    _row(
                        'الآلة الرئيسية',
                        (_data!['mainInstrument'] ?? '').toString(),
                        Icons.music_note_rounded),
                    _row('النوع (Genre)', (_data!['genre'] ?? '').toString(),
                        Icons.category_rounded),
                    _row('رقم الهاتف', (_data!['phone'] ?? '').toString(),
                        Icons.phone_rounded),
                    _row('السوشال/روابط', (_data!['social'] ?? '').toString(),
                        Icons.public_rounded),
                    _row(
                        'الموقع',
                        (_data!['location'] ?? _data!['city'] ?? '').toString(),
                        Icons.place_rounded),
                    _row('الدور', (_data!['role'] ?? '').toString(),
                        Icons.verified_user_rounded),
                    _row(
                      'تاريخ الإنشاء',
                      _data!['createdAt'] is Timestamp
                          ? (_data!['createdAt'] as Timestamp)
                              .toDate()
                              .toLocal()
                              .toString()
                          : '',
                      Icons.calendar_today_rounded,
                    ),

                    const SizedBox(height: 18),
                    const Text('منشوراتي',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),

                    if (_docId != null)
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('posts')
                            .where('authorId', isEqualTo: _docId)
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (!snap.hasData || snap.data!.docs.isEmpty) {
                            return const Center(child: Text('لا توجد منشورات'));
                          }
                          return Column(
                            children: snap.data!.docs.map(_postCard).toList(),
                          );
                        },
                      )
                  ],
                ),
    );
  }
}

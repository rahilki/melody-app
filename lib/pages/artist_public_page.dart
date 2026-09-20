import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ArtistPublicPage extends StatelessWidget {
  const ArtistPublicPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final docId = args?['docId'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف العام للفنان'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFFF5F7FB),
      body: (docId == null)
          ? const Center(child: Text('لم يتم تحديد الفنان.'))
          : FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(docId)
                  .get(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || !snap.data!.exists) {
                  return const Center(child: Text('لم يتم العثور على الفنان.'));
                }

                final d = snap.data!.data()!;
                final name =
                    (d['stageName'] ?? d['fullName'] ?? d['name'] ?? 'فنان')
                        .toString();
                final instrument = (d['mainInstrument'] ?? '').toString();
                final genre = (d['genre'] ?? '').toString();
                final location = (d['location'] ?? d['city'] ?? '').toString();
                final social = (d['social'] ?? '').toString();
                final photoUrl = (d['photoUrl'] ?? '').toString();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    // بطاقة رأس البروفايل
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF), // بنفسجي
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10)
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white24,
                            backgroundImage: photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl.isEmpty
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  name,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  [
                                    if (instrument.isNotEmpty) instrument,
                                    if (location.isNotEmpty) location,
                                  ].join(' • '),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // زر "احجز الآن" للعملاء فقط
                    FutureBuilder<String?>(
                      future: _getCurrentUserRole(),
                      builder: (context, rs) {
                        final role = (rs.data ?? '').trim().toLowerCase();
                        final isMusician = role == 'musician';
                        if (isMusician) return const SizedBox.shrink();

                        return ElevatedButton(
                          onPressed: () {
                            final data = snap.data!.data()!;
                            final musicianUid = snap.data!.id;
                            final musicianName = (data['stageName'] ??
                                    data['fullName'] ??
                                    data['name'] ??
                                    'فنان')
                                .toString();

                            Navigator.pushNamed(
                              context,
                              '/bookingDetails',
                              arguments: {
                                'musicianUid': musicianUid,
                                'musicianId': musicianUid,
                                'uid': musicianUid,
                                'docId': musicianUid,
                                'musicianName': musicianName,
                                'name': musicianName,
                              },
                            );
                          },
                          child: const Text('احجز الآن'),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    if (genre.isNotEmpty)
                      _infoRow('النوع (Genre)', genre, Icons.category_rounded),
                    if (social.isNotEmpty)
                      _infoRow('روابط/سوشال', social, Icons.public_rounded),

                    const SizedBox(height: 18),
                    const Text(
                      'منشورات الفنان ✨',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),

                    //يجيب جميع البوستات اللي كتبها الفنان
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('posts')
                          .where('authorId', isEqualTo: docId)
                          .snapshots(),
                      builder: (context, ps) {
                        if (ps.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        if (ps.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              'خطأ في جلب المنشورات: ${ps.error}',
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        if (!ps.hasData || ps.data!.docs.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Text('لا توجد منشورات بعد.'),
                            ),
                          );
                        }

                        final docs = [...ps.data!.docs];
                        docs.sort((a, b) {
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

                        return Column(
                          children: docs.map((e) {
                            final pd = e.data();
                            final title = (pd['title'] ?? '')
                                .toString(); // نجيب عنوان البوست
                            final text = (pd['text'] ?? pd['content'] ?? '')
                                .toString(); // نجيب المحتوى
                            final imageUrl =
                                (pd['imageUrl'] ?? '').toString(); // الصورة
                            final created = pd['createdAt'] is Timestamp
                                ? (pd['createdAt'] as Timestamp)
                                    .toDate()
                                    .toLocal()
                                : null;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment
                                    .end, //يخلي النصوص بمحاذاة اليمين
                                children: [
                                  if (title.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 12, 16, 6),
                                      child: Text(
                                        title,
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  if (text.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 0, 16, 10),
                                      child: Text(text,
                                          textAlign: TextAlign.right),
                                    ),
                                  if (imageUrl.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        12, 10, 12, 12),
                                    child: Row(
                                      children: [
                                        if (created != null)
                                          Text(
                                            created.toString().split('.').first,
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontSize: 12,
                                            ),
                                          ),
                                        const Spacer(),
                                        const Icon(
                                          Icons
                                              .favorite_border_rounded, //زر الايك بس ما مفعل
                                          size: 18,
                                        ),
                                        const SizedBox(width: 16),
                                        const Icon(
                                          Icons
                                              .ios_share_rounded, // زر مشاركة بس ما مفعل
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
    );
  }

  static Future<String?> _getCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString('lastEmail');
    if (last == null) return null;
    return prefs.getString('role_$last');
  }
  // نجيب الرول الحين اذا فنان ولا عميل

  static Widget _infoRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PostsFeed extends StatelessWidget {
  final String? authorId;
  const PostsFeed({super.key, this.authorId});

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> q =
        FirebaseFirestore.instance.collection('posts');

    if (authorId != null && authorId!.isNotEmpty) {
      q = q.where('authorId', isEqualTo: authorId);
    }

    // مهم: نخلي الترتيب بالأحدث، ولو createdAt null بنعرض البوست بس بدون تاريخ
    q = q.orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(), //كل ما يضاف/يتغير بوست، يحدث القائمة أوتوماتيك
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator()); // حالة التحميل دائرة
        }
        if (snap.hasError) {
          return Center(child: Text('خطأ: ${snap.error}'));
        }
        final data = snap.data;
        if (data == null || data.docs.isEmpty) {
          return const Center(child: Text('لا توجد منشورات بعد.'));
        }

        final docs = data.docs;

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: docs.length + 1, // +1 لصف Debug
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            // يظهر عدد المستندات
            if (i == 0) {
              return Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'إجمالي المنشورات: ${docs.length}',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                  textAlign: TextAlign.right,
                ),
              );
            }

            final d = docs[i - 1].data();
            final title = (d['title'] ?? d['headline'] ?? '').toString();
            final text = (d['text'] ?? d['content'] ?? '').toString();
            final authorName = (d['authorName'] ??
                    d['musicianName'] ??
                    d['stageName'] ??
                    d['fullName'] ??
                    'فنان')
                .toString();
            final authorPhoto =
                (d['authorPhoto'] ?? d['photoUrl'] ?? '').toString();

            DateTime? createdAt;
            final cts = d['createdAt'];
            if (cts is Timestamp) createdAt = cts.toDate().toLocal();

            // تصميم الكارد
            return Card(
              color: const Color(0xFFF9F7FF), // خلفية بنفسجية فاتحة
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // ====== صورة واسم الفنان ======
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFFE0D7FF),
                          backgroundImage: authorPhoto.isNotEmpty
                              ? NetworkImage(authorPhoto)
                              : null,
                          child: authorPhoto.isEmpty
                              ? const Icon(Icons.person,
                                  color: Colors.deepPurple)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            authorName,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _fmtDateTime(createdAt),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],

                    if (title.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        title,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                    if (text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        text,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          height: 1.5,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
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

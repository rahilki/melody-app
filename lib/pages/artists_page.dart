import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ArtistsPage extends StatelessWidget {
  const ArtistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'musician')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الفنانون'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q as Stream<QuerySnapshot<Map<String, dynamic>>>,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('لا يوجد فنانون حتى الآن.'));
          }

          final docs = snap.data!.docs.toList()
            ..sort((a, b) {
              String aName = (a.data()['stageName'] ??
                      a.data()['fullName'] ??
                      a.data()['name'] ??
                      '')
                  .toString();
              String bName = (b.data()['stageName'] ??
                      b.data()['fullName'] ??
                      b.data()['name'] ??
                      '')
                  .toString();
              return aName.compareTo(bName);
            });

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final docId = docs[i].id;
              final name =
                  (d['stageName'] ?? d['fullName'] ?? d['name'] ?? 'فنان')
                      .toString();
              final instrument = (d['mainInstrument'] ?? '').toString();
              final location = (d['location'] ?? d['city'] ?? '').toString();
              final photoUrl = (d['photoUrl'] ?? '').toString();

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                color: const Color(0xFFECEBFF), // بنفسجي فاتح
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl.isEmpty
                        ? const Icon(Icons.person, color: Colors.deepPurple)
                        : null,
                  ),
                  title: Text(name, textAlign: TextAlign.right),
                  subtitle: Text(
                    [
                      if (instrument.isNotEmpty) instrument,
                      if (location.isNotEmpty) location,
                    ].join(' • '),
                    textAlign: TextAlign.right,
                  ),
                  // ✅ السهم ثابت لليسار
                  trailing: const Icon(Icons.arrow_back_ios_new_rounded,
                      textDirection: TextDirection.ltr),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/artistPublic',
                      arguments: {'docId': docId},
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
}

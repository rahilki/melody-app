// lib/pages/client_home_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'common_home_scaffold.dart';
import 'posts_feed.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../theme.dart';

class ClientHomePage extends StatelessWidget {
  const ClientHomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final lastEmail = prefs.getString('lastEmail');
    if (lastEmail != null) await prefs.remove('role_$lastEmail');
    await prefs.remove('lastEmail');
    await prefs.remove('userDocId');
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    // التبويبات الداخلية:
    // 0 = الرئيسية (المنشورات)، 1 = الفعاليات (Placeholder)
    final pages = <Widget>[
      const _ClientHomeFeed(), // index 0
      const _ClientEventsTab(), // index 1
    ];

    // عناصر الشريط السفلي
    final items = <NavItemData>[
      const NavItemData(
        icon: Icons.person_rounded,
        label: 'الملف',
        onTapRoute: '/clientProfile',
      ),
      const NavItemData(
        icon: Icons.calendar_month_rounded,
        label: 'الحجوزات',
        onTapRoute: '/clientBookings',
      ),
      const NavItemData(
        icon: Icons.library_music_rounded,
        label: 'الفنانين',
        onTapRoute: '/artists',
      ),
      const NavItemData(
        icon: Icons.event_rounded,
        label: 'الفعاليات',
        pageIndex: 1, // ✅ يبدّل للتبويب الداخلي (الفعاليات)
      ),
      const NavItemData(
        icon: Icons.home_rounded,
        label: 'الرئيسية',
        pageIndex: 0, // ✅ يبدّل للتبويب الداخلي (الرئيسية)
      ),
    ];

    return CommonHomeScaffold(
      title: 'Melody',
      pages: pages,
      items: items,
      actions: const [],
    );
  }
}

// الرئيسية: تعرض جميع المنشورات (بدون authorId)
class _ClientHomeFeed extends StatelessWidget {
  const _ClientHomeFeed();
  @override
  Widget build(BuildContext context) {
    return const PostsFeed(); // يعرض كل البوستات بالأحدث
  }
}

// تبويب الفعاليات مع كالندر بارز + فلترة حسب اليوم
class _ClientEventsTab extends StatefulWidget {
  const _ClientEventsTab();
  @override
  State<_ClientEventsTab> createState() => _ClientEventsTabState();
}

class _ClientEventsTabState extends State<_ClientEventsTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  @override
  Widget build(BuildContext context) {
    final DateTime dayStart =
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final DateTime dayEnd = dayStart.add(const Duration(days: 1));

    final Stream<QuerySnapshot<Map<String, dynamic>>> eventsStream =
        FirebaseFirestore.instance
            .collection('events')
            .where('eventDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
            .where('eventDate', isLessThan: Timestamp.fromDate(dayEnd))
            .orderBy('eventDate')
            .snapshots();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // الكالندر داخل Card بارز
        Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: TableCalendar(
            locale: 'ar',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay =
                    DateTime(selected.year, selected.month, selected.day);
                _focusedDay = focused;
              });
            },

            // تنسيق الهيدر (الشهر)
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              titleTextStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              leftChevronIcon:
                  const Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon:
                  const Icon(Icons.chevron_right, color: Colors.white),
            ),

            // تنسيق الأيام
            calendarStyle: CalendarStyle(
              defaultTextStyle: const TextStyle(fontSize: 13),
              weekendTextStyle:
                  const TextStyle(fontSize: 13, color: Colors.red),
              outsideTextStyle:
                  const TextStyle(fontSize: 11, color: Colors.grey),
              todayDecoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              todayTextStyle: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),
        Text(
          'فعاليات يوم ${DateFormat('d MMMM yyyy', 'ar').format(dayStart)}',
          textAlign: TextAlign.start,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        // قائمة الفعاليات
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: eventsStream,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: const [
                    Icon(Icons.event_busy, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('لا توجد فعاليات في هذا اليوم'),
                  ],
                ),
              );
            }

            final docs = snap.data!.docs;
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final m = docs[i].data();
                final ts = m['eventDate'] as Timestamp?;
                final when = ts?.toDate();
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.event, color: AppTheme.primary),
                    title: Text(m['title'] ?? 'فعالية بدون اسم'),
                    subtitle: when == null
                        ? const Text('بدون تاريخ')
                        : Text(
                            DateFormat('h:mm a – d/M/yyyy', 'ar').format(when)),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

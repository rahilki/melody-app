import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("الفعاليات")),
      body: Column(
        children: [
          // الكالندر
          TableCalendar(
            locale: "ar", // عربي
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: const CalendarStyle(
              todayDecoration:
                  BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
              selectedDecoration:
                  BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
            ),
          ),

          const SizedBox(height: 16),

          // قائمة الفعاليات لليوم المختار
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text("اختر تاريخ لعرض الفعاليات"))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("events")
                        .where("eventDate",
                            isGreaterThanOrEqualTo: DateTime(_selectedDay!.year,
                                _selectedDay!.month, _selectedDay!.day))
                        .where("eventDate",
                            isLessThan: DateTime(_selectedDay!.year,
                                _selectedDay!.month, _selectedDay!.day + 1))
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text("لا توجد فعاليات في هذا اليوم"));
                      }
                      final docs = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final event = docs[i].data() as Map<String, dynamic>;
                          return ListTile(
                            leading:
                                const Icon(Icons.event, color: Colors.blue),
                            title: Text(event["title"] ?? "فعالية بدون اسم"),
                            subtitle: Text((event["eventDate"] as Timestamp)
                                .toDate()
                                .toString()),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

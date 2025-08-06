import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';
import '../widgets/event_form.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Event>('events');

    return Scaffold(
      appBar: AppBar(title: const Text('Meine Events')),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Event> box, _) {
          final now = DateTime.now();

          // Collect all events that are still in the future
          final upcoming = box.values
              .where((e) => (e.endDate ?? e.startDate).isAfter(now))
              .toList();

          // Expand multi-day events so that each day appears as its own entry
          final events = <Event>[];
          for (final event in upcoming) {
            var day =
                DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
            final endDay = event.endDate != null
                ? DateTime(
                    event.endDate!.year, event.endDate!.month, event.endDate!.day)
                : DateTime(event.startDate.year, event.startDate.month, event.startDate.day);

            while (!day.isAfter(endDay)) {
              events.add(Event(
                name: event.name,
                startDate: day,
                endDate: day,
                isFilled: event.isFilled,
              ));
              day = day.add(const Duration(days: 1));
            }
          }

          events.sort((a, b) => a.startDate.compareTo(b.startDate));

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final range = (event.endDate == null ||
                      event.startDate.isAtSameMomentAs(event.endDate!))
                  ? DateFormat.yMMMd().format(event.startDate)
                  : '${DateFormat.yMMMd().format(event.startDate)} – '
                      '${DateFormat.yMMMd().format(event.endDate!)}';

              return ListTile(
                title: Text(event.name),
                subtitle: Text(range),
                leading: event.isFilled
                    ? const Icon(Icons.block, color: Colors.red)
                    : const Icon(Icons.crop_square, color: Colors.blue),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (_) => const EventForm(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

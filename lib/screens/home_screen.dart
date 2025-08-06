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
          final events = box.values
              .where((e) => e.endDate.isAfter(now))
              .toList()
            ..sort((a, b) => a.startDate.compareTo(b.startDate));

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final range = event.startDate == event.endDate
                  ? DateFormat.yMMMd().format(event.startDate)
                  : '${DateFormat.yMMMd().format(event.startDate)} – ${DateFormat.yMMMd().format(event.endDate)}';

              return ListTile(
                title: Text(event.title),
                subtitle: Text('${event.time ?? 'Ganztägig'} | $range'),
                leading: event.isFullyBooked
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

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/event.dart';
import '../widgets/event_form.dart';
import '../theme/theme_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showOptions(BuildContext context, Event event, int index, Box<Event> eventBox) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Bearbeiten'),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (_) => EventForm(
                      existingEvent: event,
                      eventIndex: index,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Löschen'),
                onTap: () {
                  Navigator.pop(ctx);
                  eventBox.deleteAt(index);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Event "${event.title}" gelöscht')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Abbrechen'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Box<Event> eventBox = Hive.box<Event>('events');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? darkModeColors : lightModeColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Kalender')),
      body: ValueListenableBuilder(
        valueListenable: eventBox.listenable(),
        builder: (context, Box<Event> box, _) {
          final events = box.values.toList();
          if (events.isEmpty) {
            return const Center(child: Text('Keine Events'));
          }
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final bgColor = colors[event.colorIndex % colors.length];

              return Dismissible(
                key: Key(event.hashCode.toString()),
                direction: DismissDirection.horizontal,
                onDismissed: (direction) {
                  eventBox.deleteAt(index);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Event "${event.title}" gelöscht')),
                  );
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                secondaryBackground: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: Container(
                  color: bgColor,
                  child: ListTile(
                    title: Text(event.title),
                    subtitle: Text(
                      '${event.date.day}.${event.date.month}.${event.date.year} - '
                          '${event.date.hour.toString().padLeft(2, '0')}:${event.date.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showOptions(context, event, index, eventBox),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const EventForm(),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

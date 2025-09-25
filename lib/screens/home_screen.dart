import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/event.dart';
import '../widgets/event_form.dart';
import '../theme/theme_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showSearch = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
  }

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

  List<Event> _filterEvents(List<Event> events) {
    final query = _searchQuery.toLowerCase();
    return events.where((e) {
      final dateStr = '${e.date.day}.${e.date.month}.${e.date.year}';
      final timeStr = '${e.date.hour.toString().padLeft(2, '0')}:${e.date.minute.toString().padLeft(2, '0')}';
      return e.title.toLowerCase().contains(query) ||
          dateStr.contains(query) ||
          timeStr.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final Box<Event> eventBox = Hive.box<Event>('events');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? darkModeColors : lightModeColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => setState(() => _showSearch = !_showSearch),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: eventBox.listenable(),
        builder: (context, Box<Event> box, _) {
          final now = DateTime.now();

          final keysToDelete = box.keys
              .where((key) => box.get(key)!.date.isBefore(now))
              .toList();
          for (final key in keysToDelete) {
            box.delete(key);
          }

          final allEvents = box.values
              .where((event) => !event.date.isBefore(now))
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));

          final events = _showSearch ? _filterEvents(allEvents) : allEvents;

          return Column(
            children: [
              if (_showSearch)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Suche nach Titel, Datum oder Uhrzeit...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _showSearch = false;
                          });
                        },
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
              Expanded(
                child: events.isEmpty
                    ? const Center(child: Text('Keine Events'))
                    : ListView.builder(
                  controller: _scrollController,
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final bgColor = colors[event.colorIndex % colors.length];

                    final subtitleText = event.isAllDay
                        ? '${event.date.day}.${event.date.month}.${event.date.year}'
                        : '${event.date.day}.${event.date.month}.${event.date.year} - '
                        '${event.date.hour.toString().padLeft(2, '0')}:${event.date.minute.toString().padLeft(2, '0')}';

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
                          subtitle: Text(subtitleText),
                          trailing: IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () => _showOptions(context, event, index, eventBox),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
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

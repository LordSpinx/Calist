import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import 'models/event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(EventAdapter());
  await Hive.openBox<Event>('events');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Kalender App',
    theme: ThemeData(primarySwatch: Colors.blue),
    home: const EventListScreen(),
  );
}

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  late Box<Event> eventBox;

  @override
  void initState() {
    super.initState();
    eventBox = Hive.box<Event>('events');
    _cleanupExpiredEvents();
  }

  DateTime _heuteOhneZeit() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _istEventAktiv(Event event) {
    final heute = _heuteOhneZeit();

    final start = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
    final end = event.endDate != null
        ? DateTime(event.endDate!.year, event.endDate!.month, event.endDate!.day)
        : start;

    // Heute liegt zwischen Start und Ende inklusive
    return !heute.isBefore(start) && !heute.isAfter(end);
  }

  void _cleanupExpiredEvents() {
    final heute = _heuteOhneZeit();

    final toDelete = <int>[];
    for (var key in eventBox.keys) {
      final event = eventBox.get(key);
      if (event == null) continue;

      final end = event.endDate != null
          ? DateTime(event.endDate!.year, event.endDate!.month, event.endDate!.day)
          : DateTime(event.startDate.year, event.startDate.month, event.startDate.day);

      if (end.isBefore(heute)) {
        toDelete.add(key as int);
      }
    }

    for (var key in toDelete) {
      eventBox.delete(key);
    }
  }

  Future<void> _addEventDialog() async {
    final _formKey = GlobalKey<FormState>();
    DateTime? startDate;
    DateTime? endDate;
    String? name;
    bool isFilled = false;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Neues Event hinzufügen'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (value) => value == null || value.isEmpty ? 'Bitte Name eingeben' : null,
                        onSaved: (value) => name = value,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text('Startdatum:'),
                          const SizedBox(width: 10),
                          Text(startDate != null ? DateFormat('dd.MM.yyyy').format(startDate!) : 'kein Datum'),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) setState(() => startDate = picked);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text('Enddatum (optional):'),
                          const SizedBox(width: 10),
                          Text(endDate != null ? DateFormat('dd.MM.yyyy').format(endDate!) : 'kein Datum'),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: endDate ?? (startDate ?? DateTime.now()),
                                firstDate: startDate ?? DateTime.now(),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) setState(() => endDate = picked);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text('Jeden Tag markieren?'),
                          Checkbox(
                            value: isFilled,
                            onChanged: (v) => setState(() => isFilled = v ?? false),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  _formKey.currentState!.save();
                  if (startDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bitte Startdatum wählen')));
                    return;
                  }
                  if (endDate != null && endDate!.isBefore(startDate!)) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enddatum darf nicht vor Startdatum liegen')));
                    return;
                  }

                  final event = Event(
                    name: name!,
                    startDate: startDate!,
                    endDate: endDate,
                    isFilled: isFilled,
                  );

                  eventBox.add(event);
                  Navigator.pop(context);
                  setState(() {}); // neu laden
                }
              },
              child: const Text('Hinzufügen'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = eventBox.values.where(_istEventAktiv).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    return Scaffold(
      appBar: AppBar(title: const Text('Kalender App')),
      body: events.isEmpty
          ? const Center(child: Text('Keine Events'))
          : ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];

          final startFormatted = DateFormat('dd.MM.yyyy').format(event.startDate);
          final endFormatted = event.endDate != null ? DateFormat('dd.MM.yyyy').format(event.endDate!) : null;

          return ListTile(
            title: Text(event.name),
            subtitle: Text(endFormatted == null
                ? startFormatted
                : event.isFilled
                ? '$startFormatted bis $endFormatted (jeden Tag markiert)'
                : '$startFormatted bis $endFormatted (nur Start/Ende markiert)'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                event.delete();
                setState(() {});
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEventDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

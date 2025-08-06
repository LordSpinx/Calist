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
    if (event.isFilled) {
      // jeder Tag innerhalb des Bereichs wird angezeigt
      return !heute.isBefore(start) && !heute.isAfter(end);
    }
    // nur Start- und Endtag werden angezeigt
    return heute.isAtSameMomentAs(start) || heute.isAtSameMomentAs(end);
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
    String? name;
    bool isAllDay = false;
    bool onlyStartEnd = false;
    DateTime start = DateTime.now();
    DateTime end = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Neues Event hinzufügen'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              String format(DateTime dt) =>
                  DateFormat(isAllDay ? 'dd.MM.yyyy' : 'dd.MM.yyyy HH:mm').format(dt);

              Future<void> pickStart() async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: start,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date == null) return;
                if (isAllDay) {
                  setDialogState(() => start = DateTime(date.year, date.month, date.day));
                } else {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(start),
                  );
                  if (time != null) {
                    setDialogState(() =>
                        start = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                  }
                }
              }

              Future<void> pickEnd() async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: end.isBefore(start) ? start : end,
                  firstDate: start,
                  lastDate: DateTime(2100),
                );
                if (date == null) return;
                if (isAllDay) {
                  setDialogState(() => end = DateTime(date.year, date.month, date.day));
                } else {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(end),
                  );
                  if (time != null) {
                    setDialogState(() =>
                        end = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                  }
                }
              }

              return SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Bitte Name eingeben' : null,
                        onSaved: (value) => name = value,
                      ),
                      SwitchListTile(
                        title: const Text('Ganztägig'),
                        contentPadding: EdgeInsets.zero,
                        value: isAllDay,
                        onChanged: (v) => setDialogState(() => isAllDay = v),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Von:'),
                        subtitle: Text(format(start)),
                        onTap: pickStart,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Bis:'),
                        subtitle: Text(format(end)),
                        onTap: pickEnd,
                      ),
                      SwitchListTile(
                        title: const Text('Nur Start und Ende'),
                        contentPadding: EdgeInsets.zero,
                        value: onlyStartEnd,
                        onChanged: (v) => setDialogState(() => onlyStartEnd = v),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  _formKey.currentState!.save();
                  if (end.isBefore(start)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ende darf nicht vor Start liegen')));
                    return;
                  }
                  final event = Event(
                    name: name!,
                    startDate: start,
                    endDate: end,
                    isFilled: !onlyStartEnd,
                  );
                  eventBox.add(event);
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              child: const Text('Fertig'),
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

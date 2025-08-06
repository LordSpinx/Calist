import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/event.dart';

class EventForm extends StatefulWidget {
  const EventForm({super.key});

  @override
  State<EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<EventForm> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String? time;
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  bool isFullyBooked = true;

  Future<void> pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Neues Event'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Titel'),
                validator: (value) => value == null || value.isEmpty ? 'Titel erforderlich' : null,
                onSaved: (value) => title = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Uhrzeit (optional)'),
                onSaved: (value) => time = value,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Von: ${startDate.toLocal().toString().split(' ')[0]}\nBis: ${endDate.toLocal().toString().split(' ')[0]}',
                    ),
                  ),
                  TextButton(
                    onPressed: pickDateRange,
                    child: const Text('Datum wählen'),
                  ),
                ],
              ),
              CheckboxListTile(
                title: const Text('Jeden Tag belegt?'),
                value: isFullyBooked,
                onChanged: (val) {
                  setState(() => isFullyBooked = val ?? true);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              _formKey.currentState!.save();
              final box = Hive.box<Event>('events');
              box.add(Event(
                title: title,
                startDate: startDate,
                endDate: endDate,
                time: time,
                isFullyBooked: isFullyBooked,
              ));
              Navigator.pop(context);
            }
          },
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}

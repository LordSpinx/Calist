import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/event.dart';
import '../theme/theme_colors.dart';

class EventForm extends StatefulWidget {
  final Event? existingEvent;
  final int? eventIndex;

  const EventForm({super.key, this.existingEvent, this.eventIndex});

  @override
  State<EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<EventForm> {
  late TextEditingController _titleController;
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  bool _isAllDay = false;
  bool _splitByDay = true;
  int _selectedColorIndex = 0;

  @override
  void initState() {
    super.initState();
    final title = widget.existingEvent?.title.replaceAll(RegExp(r' (Start|Ende)\$'), '') ?? '';
    _titleController = TextEditingController(text: title);

    final date = widget.existingEvent?.date;
    if (date != null) {
      _startDateTime = date;
      _endDateTime = date;
    }

    _selectedColorIndex = widget.existingEvent?.colorIndex ?? 0;
  }

  void _saveEvent() {
    if (_titleController.text.isEmpty || _startDateTime == null) return;

    _endDateTime ??= _startDateTime;
    if (_startDateTime!.isAfter(_endDateTime!)) return;

    final eventBox = Hive.box<Event>('events');
    if (widget.eventIndex != null) {
      eventBox.deleteAt(widget.eventIndex!);
    }

    if (_splitByDay) {
      DateTime current = _startDateTime!;
      while (!current.isAfter(_endDateTime!)) {
        eventBox.add(Event(
          title: _titleController.text,
          date: _isAllDay ? DateTime(current.year, current.month, current.day) : current,
          colorIndex: _selectedColorIndex,
        ));
        current = current.add(const Duration(days: 1));
      }
    } else {
      eventBox.add(Event(
        title: "${_titleController.text} Start",
        date: _isAllDay
            ? DateTime(_startDateTime!.year, _startDateTime!.month, _startDateTime!.day)
            : _startDateTime!,
        colorIndex: _selectedColorIndex,
      ));

      if (!_startDateTime!.isAtSameMomentAs(_endDateTime!)) {
        eventBox.add(Event(
          title: "${_titleController.text} Ende",
          date: _isAllDay
              ? DateTime(_endDateTime!.year, _endDateTime!.month, _endDateTime!.day)
              : _endDateTime!,
          colorIndex: _selectedColorIndex,
        ));
      }
    }

    Navigator.of(context).pop();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate == null) return;

    if (!_isAllDay) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now),
      );

      if (pickedTime == null) return;

      final fullDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      setState(() {
        if (isStart) {
          _startDateTime = fullDateTime;
        } else {
          _endDateTime = fullDateTime;
        }
      });
    } else {
      final fullDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
      setState(() {
        if (isStart) {
          _startDateTime = fullDate;
        } else {
          _endDateTime = fullDate;
        }
      });
    }
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Nicht gewählt';
    return _isAllDay
        ? '${dt.day}.${dt.month}.${dt.year}'
        : '${dt.day}.${dt.month}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? darkModeColors : lightModeColors;

    return AlertDialog(
      title: const Text('Neues Event'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Titel'),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: List.generate(colors.length, (index) {
                final selected = _selectedColorIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColorIndex = index),
                  child: CircleAvatar(
                    backgroundColor: colors[index],
                    radius: selected ? 18 : 14,
                    child: selected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text('Ganztägig'),
              value: _isAllDay,
              onChanged: (val) => setState(() => _isAllDay = val),
            ),
            ListTile(
              title: const Text('Startzeit'),
              subtitle: Text(_formatDateTime(_startDateTime)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDateTime(isStart: true),
            ),
            ListTile(
              title: const Text('Endzeit'),
              subtitle: Text(_formatDateTime(_endDateTime)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDateTime(isStart: false),
            ),
            SwitchListTile(
              title: const Text('Alle Tage anzeigen'),
              value: _splitByDay,
              onChanged: (val) => setState(() => _splitByDay = val),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Abbrechen')),
        ElevatedButton(onPressed: _saveEvent, child: const Text('Speichern')),
      ],
    );
  }
}

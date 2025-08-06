import 'package:hive/hive.dart';

part 'event.g.dart';

@HiveType(typeId: 0)
class Event extends HiveObject {
  @HiveField(0)
  DateTime startDate;

  @HiveField(1)
  DateTime? endDate; // optional für mehrtägige Events

  @HiveField(2)
  String name;

  @HiveField(3)
  bool isFilled; // true = jeden Tag markieren, false = nur Start/Ende

  Event({
    required this.startDate,
    this.endDate,
    required this.name,
    this.isFilled = false,
  });
}

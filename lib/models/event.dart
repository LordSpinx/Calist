import 'package:hive/hive.dart';

part 'event.g.dart';

@HiveType(typeId: 0)
class Event {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final int colorIndex;

  Event({required this.title, required this.date, required this.colorIndex});
}

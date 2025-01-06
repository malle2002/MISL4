import 'package:hive/hive.dart';

part 'ExamEvent.g.dart';

@HiveType(typeId: 0)
class ExamEvent {
  @HiveField(0)
  String title;

  @HiveField(1)
  DateTime dateTime;

  @HiveField(2)
  String location;

  @HiveField(3)
  double latitude;

  @HiveField(4)
  double longitude;

  ExamEvent({
    required this.title,
    required this.dateTime,
    required this.location,
    required this.latitude,
    required this.longitude,
  });
}

import 'package:hive/hive.dart';

part 'user_productivity.g.dart';

@HiveType(typeId: 4)
class UserProductivity extends HiveObject {
  @HiveField(0)
  int currentStreak;

  @HiveField(1)
  int longestStreak;

  @HiveField(2)
  DateTime? lastCompletedDate;

  @HiveField(3)
  int totalCompletedSessions;

  @HiveField(4)
  int streakFreezes;

  UserProductivity({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletedDate,
    this.totalCompletedSessions = 0,
    this.streakFreezes = 0,
  });
}

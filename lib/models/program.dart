import 'package:hive/hive.dart';

part 'program.g.dart';

@HiveType(typeId: 3)
class Program extends HiveObject {
  @HiveField(0)
  late String institution;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String level;

  @HiveField(3)
  late int semester;

  @HiveField(4)
  late String? department;

  @HiveField(5)
  late String? group;

  Program({
    required this.institution,
    required this.name,
    required this.level,
    required this.semester,
    this.department,
    this.group,
  });
}

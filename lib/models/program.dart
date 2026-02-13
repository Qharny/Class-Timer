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

  Program({
    required this.institution,
    required this.name,
    required this.level,
    required this.semester,
  });
}

class TimeSlotModel {
  final String label;
  final DateTime startTime;
  final DateTime endTime;
  final int columnIndex;

  TimeSlotModel({
    required this.label,
    required this.startTime,
    required this.endTime,
    required this.columnIndex,
  });
}

class VenueModel {
  final String name;
  final int rowIndex;

  VenueModel({required this.name, required this.rowIndex});
}

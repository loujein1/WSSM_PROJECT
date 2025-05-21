class WaterUsage {
  final String userKey;
  final String datetime;
  final int meterReading;
  final int diff;

  WaterUsage({
    required this.userKey,
    required this.datetime,
    required this.meterReading,
    required this.diff,
  });

  // Getter to access the amount used (which is represented by diff)
  int get amountUsed => diff;

  // ✅ Convert JSON map to WaterUsage object
  factory WaterUsage.fromJson(Map<String, dynamic> json) {
    return WaterUsage(
      userKey: json['user key'] ?? '',
      datetime: json['datetime'] ?? '',
      meterReading: (json['meter reading'] ?? 0).toInt(),
      diff: (json['diff'] ?? 0).toInt(),
    );
  }
}

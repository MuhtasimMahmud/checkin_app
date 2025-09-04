class Attendance {
  final String userId;
  final String pointId;
  final String status; // 'in' | 'out'
  final DateTime lastUpdated;
  final double? lastLat;
  final double? lastLng;

  Attendance({
    required this.userId,
    required this.pointId,
    required this.status,
    required this.lastUpdated,
    this.lastLat,
    this.lastLng,
  });
}

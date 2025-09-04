class CheckInPoint {
  final String id;
  final double lat;
  final double lng;
  final double radiusMeters;
  final String createdBy;
  final DateTime createdAt;
  final bool active;

  CheckInPoint({
    required this.id,
    required this.lat,
    required this.lng,
    required this.radiusMeters,
    required this.createdBy,
    required this.createdAt,
    required this.active,
  });
}

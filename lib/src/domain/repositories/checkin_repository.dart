import '../entities/checkin_point.dart';

abstract class CheckInRepository {
  // Active point state (stream)
  Stream<CheckInPoint?> watchActivePoint();
  Future<CheckInPoint?> fetchActivePointOnce();

  Future<void> createActivePoint({
    required double lat,
    required double lng,
    required double radiusMeters,
    required String createdBy,
  });

  Future<void> clearActivePoint();

  // Attendance
  Stream<int> watchLiveCount(String pointId);
  Future<void> checkIn({
    required String pointId,
    required String userId,
    required double lat,
    required double lng,
  });
  Future<void> checkOut({
    required String pointId,
    required String userId,
    required double lat,
    required double lng,
  });

  // Destroy (creator only)
  Future<void> destroyActivePointIfOwner({required String userId});
}

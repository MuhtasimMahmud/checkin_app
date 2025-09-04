import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import '../../domain/entities/checkin_point.dart';
import '../../domain/repositories/checkin_repository.dart';
import '../datasources/firestore_service.dart';

class CheckInRepositoryImpl implements CheckInRepository {
  final _fs = FirestoreService();

  @override
  Stream<CheckInPoint?> watchActivePoint() {
    final ref = _fs.doc(FirestorePaths.stateDoc);
    return ref.snapshots().map(_mapStateSnapToPoint);
  }

  // NEW: manual refresh (one-shot fetch)
  @override
  Future<CheckInPoint?> fetchActivePointOnce() async {
    final ref = _fs.doc(FirestorePaths.stateDoc);
    final snap = await ref.get();
    return _mapStateSnapToPoint(snap);
  }

  CheckInPoint? _mapStateSnapToPoint(
      DocumentSnapshot<Map<String, dynamic>> snap) {
    if (!snap.exists) return null;
    final data = snap.data()!;
    final ts = data['createdAt'];
    final createdAt = ts is Timestamp ? ts.toDate() : DateTime.now();
    return CheckInPoint(
      id: (data['pointId'] as String?) ?? 'active',
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      radiusMeters: (data['radiusMeters'] as num).toDouble(),
      createdBy: data['createdBy'] as String? ?? 'unknown',
      createdAt: createdAt,
      active: data['active'] as bool? ?? true,
    );
  }

  @override
  Future<void> createActivePoint({
    required double lat,
    required double lng,
    required double radiusMeters,
    required String createdBy,
  }) async {
    final points = _fs.col(FirestorePaths.pointsCol).doc();
    final batch = _fs.db.batch();
    batch.set(points, {
      'lat': lat,
      'lng': lng,
      'radiusMeters': radiusMeters,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'active': true,
    });
    batch.set(_fs.doc(FirestorePaths.stateDoc), {
      'pointId': points.id,
      'lat': lat,
      'lng': lng,
      'radiusMeters': radiusMeters,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'active': true,
    });
    await batch.commit();
  }

  @override
  Future<void> clearActivePoint() async {
    await _fs.doc(FirestorePaths.stateDoc).delete();
  }

  @override
  Stream<int> watchLiveCount(String pointId) {
    final col = _fs
        .col(FirestorePaths.attendances(pointId))
        .where('status', isEqualTo: 'in');
    return col.snapshots().map((q) => q.size);
  }

  @override
  Future<void> checkIn({
    required String pointId,
    required String userId,
    required double lat,
    required double lng,
  }) async {
    final doc = _fs.col(FirestorePaths.attendances(pointId)).doc(userId);
    await doc.set({
      'userId': userId,
      'pointId': pointId,
      'status': 'in',
      'lastUpdated': FieldValue.serverTimestamp(),
      'lastLat': lat,
      'lastLng': lng,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> checkOut({
    required String pointId,
    required String userId,
    required double lat,
    required double lng,
  }) async {
    final doc = _fs.col(FirestorePaths.attendances(pointId)).doc(userId);
    await doc.set({
      'userId': userId,
      'pointId': pointId,
      'status': 'out',
      'lastUpdated': FieldValue.serverTimestamp(),
      'lastLat': lat,
      'lastLng': lng,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> destroyActivePointIfOwner({required String userId}) async {
    final stateRef = _fs.doc(FirestorePaths.stateDoc);
    final stateSnap = await stateRef.get();
    if (!stateSnap.exists) return;

    final data = stateSnap.data()!;
    final createdBy = data['createdBy'] as String? ?? '';
    final pointId = data['pointId'] as String?;
    if (createdBy != userId || pointId == null) return;

    // delete all attendances
    final attendsCol = _fs.col(FirestorePaths.attendances(pointId));
    const pageSize = 200;
    while (true) {
      final page = await attendsCol.limit(pageSize).get();
      if (page.docs.isEmpty) break;
      final batch = _fs.db.batch();
      for (final d in page.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }

    // delete point + state
    await _fs.col(FirestorePaths.pointsCol).doc(pointId).delete();
    await stateRef.delete();
  }
}

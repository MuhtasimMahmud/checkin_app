import 'dart:async';
import 'package:checkin_app/src/domain/entities/checkin_point.dart';
import 'package:checkin_app/src/domain/repositories/checkin_repository.dart';
import 'package:checkin_app/src/domain/repositories/location_repository.dart';
import 'package:get/get.dart';

class MapController extends GetxController {
  final LocationRepository _loc;
  final CheckInRepository _repo;
  MapController(this._loc, this._repo);

  final activePoint = Rxn<CheckInPoint>();
  final permissionOk = false.obs;

  StreamSubscription? _sub;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    permissionOk.value = await _loc.ensurePermission();
    await _loc.warmup();
    _sub = _repo.watchActivePoint().listen((p) => activePoint.value = p);
  }

  // NEW: manual refresh (AppBar button)
  Future<void> refreshActivePoint() async {
    final p = await _repo.fetchActivePointOnce();
    activePoint.value = p;
  }

  Future<void> createPoint({
    required double lat,
    required double lng,
    required double radiusMeters,
    required String createdBy,
  }) async {
    await _repo.createActivePoint(
      lat: lat,
      lng: lng,
      radiusMeters: radiusMeters,
      createdBy: createdBy,
    );
  }

  Future<void> clearPoint() async {
    await _repo.clearActivePoint();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}

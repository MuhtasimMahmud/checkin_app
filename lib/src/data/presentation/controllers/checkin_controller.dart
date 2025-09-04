import 'dart:async';
import 'package:checkin_app/src/domain/entities/checkin_point.dart';
import 'package:checkin_app/src/domain/repositories/auth_repository.dart';
import 'package:checkin_app/src/domain/repositories/checkin_repository.dart';
import 'package:checkin_app/src/domain/repositories/location_repository.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

class CheckInController extends GetxController {
  final AuthRepository _auth;
  final LocationRepository _loc;
  final CheckInRepository _repo;

  CheckInController(this._auth, this._loc, this._repo);

  final liveCount = 0.obs;
  final withinRange = false.obs;
  final lastDistance = 0.0.obs;
  final lastLat = RxnDouble();
  final lastLng = RxnDouble();
  final isCheckedIn =
      false.obs; // local state to avoid spamming writes on every poll

  StreamSubscription? _pointSub;
  StreamSubscription? _countSub;
  Timer? _pollTimer;
  CheckInPoint? _point;

  @override
  void onInit() {
    super.onInit();
    _pointSub = _repo.watchActivePoint().listen((p) {
      _point = p;
      _watchCount();
      // Reset local state when point changes
      isCheckedIn.value = false;
      withinRange.value = false;
    });
    _pollTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _checkProximity());
  }

  void _watchCount() {
    _countSub?.cancel();
    final pid = _point?.id;
    if (pid == null) {
      liveCount.value = 0;
      return;
    }
    _countSub = _repo.watchLiveCount(pid).listen((c) => liveCount.value = c);
  }

  Future<void> _checkProximity() async {
    final p = _point;
    if (p == null) {
      withinRange.value = false;
      return;
    }
    final pos = await Geolocator.getCurrentPosition();
    lastLat.value = pos.latitude;
    lastLng.value = pos.longitude;

    final d =
        Geolocator.distanceBetween(p.lat, p.lng, pos.latitude, pos.longitude);
    lastDistance.value = d;
    final nowWithin = d <= p.radiusMeters;
    final uid = _auth.currentUserId();

    // Transition-based logic to prevent write flood
    if (nowWithin && !isCheckedIn.value && uid != null) {
      await _repo.checkIn(
        pointId: p.id,
        userId: uid,
        lat: pos.latitude,
        lng: pos.longitude,
      );
      isCheckedIn.value = true;
    } else if (!nowWithin && isCheckedIn.value && uid != null) {
      await _repo.checkOut(
        pointId: p.id,
        userId: uid,
        lat: pos.latitude,
        lng: pos.longitude,
      );
      isCheckedIn.value = false;
    }

    withinRange.value = nowWithin;
  }

  /// Only creator should call this (UI will guard). Repo will double-check.
  Future<void> destroyActiveIfOwner() async {
    final uid = _auth.currentUserId();
    if (uid != null) {
      await _repo.destroyActivePointIfOwner(userId: uid);
    }
  }

  @override
  void onClose() {
    _countSub?.cancel();
    _pointSub?.cancel();
    _pollTimer?.cancel();
    super.onClose();
  }
}

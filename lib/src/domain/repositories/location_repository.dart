abstract class LocationRepository {
  Future<bool> ensurePermission();
  Future<void> warmup();
}

import 'package:checkin_app/src/data/datasources/directions_service.dart';
import 'package:checkin_app/src/data/presentation/controllers/auth_controller.dart';
import 'package:checkin_app/src/data/presentation/controllers/checkin_controller.dart';
import 'package:checkin_app/src/data/presentation/controllers/map_controller.dart';
import 'package:get/get.dart';

import '../core/secrets.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/location_repository.dart';
import '../domain/repositories/checkin_repository.dart';

import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/location_repository_impl.dart';
import '../data/repositories/checkin_repository_impl.dart';

class GlobalBindings extends Bindings {
  @override
  void dependencies() {
    // Register repositories against their interfaces
    Get.put<AuthRepository>(AuthRepositoryImpl(), permanent: true);
    Get.put<LocationRepository>(LocationRepositoryImpl(), permanent: true);
    Get.put<CheckInRepository>(CheckInRepositoryImpl(), permanent: true);

    Get.put(DirectionsService(kGoogleMapsApiKey), permanent: true);

    // Register controllers and resolve by interface
    Get.put<AuthController>(AuthController(Get.find<AuthRepository>()),
        permanent: true);
    Get.put<MapController>(
        MapController(
          Get.find<LocationRepository>(),
          Get.find<CheckInRepository>(),
        ),
        permanent: true);
    Get.put<CheckInController>(
        CheckInController(
          Get.find<AuthRepository>(),
          Get.find<LocationRepository>(),
          Get.find<CheckInRepository>(),
        ),
        permanent: true);
  }
}

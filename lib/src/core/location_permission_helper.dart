import 'package:geolocator/geolocator.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';

class LocationPermissionHelper {
  /// Force user to enable location service + grant permission.
  /// Blocks until success.
  static Future<void> ensureLocationPermission(BuildContext context) async {
    while (true) {
      // 1. Check if service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _showDialog(
          context,
          'Location Service Required',
          'This app requires GPS/Location to be ON. Please enable it.',
          onOk: () => AppSettings.openAppSettings(),
        );
        continue; // loop again after user tries
      }

      // 2. Check permission
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.deniedForever) {
        await _showDialog(
          context,
          'Permission Required',
          'Location permission is permanently denied. Please enable from settings.',
          onOk: () => AppSettings.openAppSettings(),
        );
        continue;
      }

      if (perm == LocationPermission.denied) {
        // user denied again
        continue;
      }

      // If we reach here → service ON & permission granted
      return;
    }
  }

  static Future<void> _showDialog(
    BuildContext context,
    String title,
    String msg, {
    required VoidCallback onOk,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: onOk,
            child: const Text('Open Settings'),
          )
        ],
      ),
    );
  }
}

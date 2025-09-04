import 'dart:async';
import 'package:checkin_app/src/data/datasources/directions_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../controllers/map_controller.dart';
import '../controllers/checkin_controller.dart';
import '../controllers/auth_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Controllers
  final mapC = Get.find<MapController>();
  final checkC = Get.find<CheckInController>();
  final authC = Get.find<AuthController>();
  final dirService = Get.find<DirectionsService>();

  // GoogleMap
  final Completer<GoogleMapController> _gm = Completer();
  static const _dhaka = LatLng(23.777176, 90.399452);

  // In-app routing state
  List<LatLng> _route = [];
  bool _isRouting = false;

  // Auto-refresh timer for route (optional; keep if you added earlier)
  Timer? _routeTimer;
  static const _routeRefreshInterval = Duration(seconds: 60);

  @override
  void initState() {
    super.initState();
    _routeTimer =
        Timer.periodic(_routeRefreshInterval, (_) => _maybeAutoRefreshRoute());
  }

  @override
  void dispose() {
    _routeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text('People Arrived : ${checkC.liveCount.value}')),
        actions: [
          // Refresh active point (manual force refresh)
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await mapC.refreshActivePoint();
              await _focusOnActivePoint();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Refreshed'),
                      behavior: SnackBarBehavior.floating),
                );
              }
            },
          ),
          IconButton(
            onPressed: () => authC.ensureSignedIn(),
            icon: const Icon(Icons.person_outline),
            tooltip: 'Ensure Anonymous Sign-In',
          ),
        ],
      ),
      body: Obx(() {
        final p = mapC.activePoint.value;

        final Set<Marker> markers = {};
        final Set<Circle> circles = {};
        final Set<Polyline> polylines = {};

        LatLng? me;
        if (checkC.lastLat.value != null && checkC.lastLng.value != null) {
          me = LatLng(checkC.lastLat.value!, checkC.lastLng.value!);
        }

        if (p != null) {
          final center = LatLng(p.lat, p.lng);
          markers.add(Marker(markerId: MarkerId(p.id), position: center));
          circles.add(Circle(
            circleId: CircleId(p.id),
            center: center,
            radius: p.radiusMeters,
            fillColor: Colors.indigo.withOpacity(0.2),
            strokeColor: Colors.indigo,
            strokeWidth: 2,
          ));
        }

        if (_route.isNotEmpty) {
          polylines.add(Polyline(
            polylineId: const PolylineId('route_polyline'),
            points: _route,
            width: 6,
          ));
        } else {
          if (me != null && p != null) {
            polylines.add(Polyline(
              polylineId: const PolylineId('me_to_point'),
              points: [me, LatLng(p.lat, p.lng)],
              width: 3,
            ));
          }
        }

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition:
                  const CameraPosition(target: _dhaka, zoom: 14),
              myLocationEnabled: true, // shows the blue dot
              myLocationButtonEnabled: false, // we’ll use our own big button
              onMapCreated: (c) => _gm.complete(c),
              markers: markers,
              circles: circles,
              polylines: polylines,
              onLongPress: (latLng) =>
                  p == null ? _onLongPressCreate(latLng) : null,
            ),

            // Bottom info panel
            Positioned(
              left: 12,
              right: 12,
              bottom: 20,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (p == null) ...[
                        const Text(
                          'No active check-in location. Long-press map to create.',
                          style: TextStyle(
                              color: Colors.red,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                        ),
                      ] else ...[
                        Text('Radius: ${p.radiusMeters.toStringAsFixed(0)} m'),
                        const SizedBox(height: 6),
                        Obx(() => Text(
                              'Distance: ${checkC.lastDistance.value.toStringAsFixed(1)} m — '
                              'Within: ${checkC.withinRange.value} — '
                              'Status: ${checkC.isCheckedIn.value ? "IN" : "OUT"}',
                            )),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    _isRouting ? null : () => _drawInAppRoute(),
                                icon: const Icon(Icons.alt_route),
                                label: Text(_isRouting
                                    ? 'Routing…'
                                    : 'Show/Refresh Route'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (p != null && authC.userId.value == p.createdBy)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await checkC.destroyActiveIfOwner();
                                    if (mounted) setState(() => _route = []);
                                  },
                                  icon: const Icon(Icons.delete_forever),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade700,
                                    foregroundColor: Colors.white,
                                  ),
                                  label: const Text('Destroy'),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              top: 20,
              right: 16,
              child: SizedBox(
                height: 60,
                width: 60,
                child: FloatingActionButton(
                  heroTag: 'my_location_fab',
                  backgroundColor: Colors.indigo,
                  elevation: 6,
                  onPressed: _goToMyLocation,
                  child: const Icon(Icons.my_location,
                      size: 30, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Manual Refresh Helpers
  Future<void> _focusOnActivePoint() async {
    final p = mapC.activePoint.value;
    if (p == null) return;
    final c = await _gm.future;
    try {
      await c
          .animateCamera(CameraUpdate.newLatLngZoom(LatLng(p.lat, p.lng), 15));
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────
  // Create point (long-press)
  Future<void> _onLongPressCreate(LatLng pos) async {
    await authC.ensureSignedIn();
    final r = await showDialog<double>(
      context: context,
      builder: (_) => const _RadiusDialog(),
    );
    if (r == null) return;
    await mapC.createPoint(
      lat: pos.latitude,
      lng: pos.longitude,
      radiusMeters: r,
      createdBy: authC.userId.value ?? 'unknown',
    );
    final c = await _gm.future;
    await c.animateCamera(CameraUpdate.newLatLng(pos));
  }

  // ─────────────────────────────────────────────────────────────
  // In-app route (with API guard & safe bounds)
  Future<void> _drawInAppRoute() async {
    final p = mapC.activePoint.value;
    if (p == null) return;

    setState(() => _isRouting = true);

    LatLng? origin;
    if (checkC.lastLat.value != null && checkC.lastLng.value != null) {
      origin = LatLng(checkC.lastLat.value!, checkC.lastLng.value!);
    }
    origin ??= _dhaka;
    final dest = LatLng(p.lat, p.lng);

    final result = await dirService.getRoutePolyline(
      origin: origin,
      destination: dest,
      mode: 'walking',
    );

    if (!mounted) return;

    if (result.error != null || result.points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              // 'Route unavailable (${result.error}). Showing straight guide line.'),
              'Showing straight guide line.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _route = [];
        _isRouting = false;
      });
      await _fitToBounds([origin, dest]);
      return;
    }

    setState(() {
      _route = result.points;
      _isRouting = false;
    });

    await _fitToBounds(_route);
  }

  // Auto refresh route every 60s, if already drawn
  Future<void> _maybeAutoRefreshRoute() async {
    if (_route.isEmpty) return;
    final p = mapC.activePoint.value;
    if (p == null || _isRouting) return;
    await _drawInAppRoute(); // reuse same method (shows subtle snackbar only on error)
  }

  // ─────────────────────────────────────────────────────────────
  // BIG My Location button handler — always centers to a fresh, high-accuracy fix
  Future<void> _goToMyLocation() async {
    try {
      // Ensure services & permission
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _snack('Please enable Location Services (GPS).');
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _snack('Location permission is required to center on your position.');
        return;
      }

      // Get a fresh, high-accuracy fix
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      final c = await _gm.future;
      await c.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(pos.latitude, pos.longitude),
            zoom: 17, // a bit closer to feel precise
            tilt: 0,
            bearing: 0,
          ),
        ),
      );
    } catch (e) {
      _snack('Couldn’t get current location. ${e.toString()}');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Bounds helpers
  Future<void> _fitToBounds(List<LatLng> pts) async {
    final c = await _gm.future;
    final bounds = _boundsFrom(pts);
    try {
      await c.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
    } catch (_) {
      try {
        await c.animateCamera(CameraUpdate.newLatLngBounds(bounds, 20));
      } catch (_) {
        if (pts.isNotEmpty) {
          await c.animateCamera(CameraUpdate.newLatLng(pts.last));
        }
      }
    }
  }

  LatLngBounds _boundsFrom(List<LatLng> pts) {
    if (pts.length == 1) {
      final p = pts.first;
      return LatLngBounds(
        southwest: LatLng(p.latitude - 0.0005, p.longitude - 0.0005),
        northeast: LatLng(p.latitude + 0.0005, p.longitude + 0.0005),
      );
    }
    double? minLat, maxLat, minLng, maxLng;
    for (final p in pts) {
      minLat = (minLat == null)
          ? p.latitude
          : (p.latitude < minLat ? p.latitude : minLat);
      maxLat = (maxLat == null)
          ? p.latitude
          : (p.latitude > maxLat ? p.latitude : maxLat);
      minLng = (minLng == null)
          ? p.longitude
          : (p.longitude < minLng ? p.longitude : minLng);
      maxLng = (maxLng == null)
          ? p.longitude
          : (p.longitude > maxLng ? p.longitude : maxLng);
    }
    if (minLat == maxLat && minLng == maxLng) {
      minLat = minLat! - 0.0005;
      maxLat = maxLat! + 0.0005;
      minLng = minLng! - 0.0005;
      maxLng = maxLng! + 0.0005;
    }
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }
}

class _RadiusDialog extends StatefulWidget {
  const _RadiusDialog();

  @override
  State<_RadiusDialog> createState() => _RadiusDialogState();
}

class _RadiusDialogState extends State<_RadiusDialog> {
  final controller = TextEditingController(text: '100');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set radius (meters)'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.circle)),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final v = double.tryParse(controller.text);
            if (v == null || v <= 0) return;
            Navigator.pop(context, v);
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class DirectionsResult {
  final List<LatLng> points;
  final String? error; // null হলে OK

  DirectionsResult(this.points, {this.error});
}

class DirectionsService {
  DirectionsService(this.apiKey);

  final String apiKey;

  /// mode: driving | walking | bicycling | transit
  Future<DirectionsResult> getRoutePolyline({
    required LatLng origin,
    required LatLng destination,
    String mode = 'walking',
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&mode=$mode'
      '&key=$apiKey',
    );

    try {
      final res = await http.get(url).timeout(timeout);
      if (res.statusCode != 200) {
        return DirectionsResult(const [], error: 'HTTP ${res.statusCode}');
      }

      final data = json.decode(res.body) as Map<String, dynamic>;
      final status = (data['status'] as String?) ?? 'UNKNOWN';

      if (status != 'OK') {
        // Common statuses: ZERO_RESULTS, OVER_DAILY_LIMIT, OVER_QUERY_LIMIT, REQUEST_DENIED, INVALID_REQUEST
        return DirectionsResult(const [], error: status);
      }

      final routes = (data['routes'] as List?) ?? [];
      if (routes.isEmpty) {
        return DirectionsResult(const [], error: 'NO_ROUTES');
      }

      final poly = routes.first['overview_polyline']?['points'] as String?;
      if (poly == null) {
        return DirectionsResult(const [], error: 'NO_POLYLINE');
      }

      final pts = PolylinePoints.decodePolyline(poly);
      final ll = pts.map((p) => LatLng(p.latitude, p.longitude)).toList();
      return DirectionsResult(ll);
    } on Exception catch (e) {
      // timeout/parse/other errors
      return DirectionsResult(const [], error: e.toString());
    }
  }
}

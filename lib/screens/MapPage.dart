import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:lab4/models/ExamEvent.dart';
import '../util/utils.dart';

class MapPage extends StatefulWidget {
  final List<ExamEvent> events;

  MapPage(this.events);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentLocation;
  Marker? _currentLocationMarker;
  bool _isFetchingRoute = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _populateMarkers();
  }

  void _populateMarkers() {
    for (var event in widget.events) {
      _markers.add(
        Marker(
          markerId: MarkerId(event.title),
          position: LatLng(event.latitude, event.longitude),
          infoWindow: InfoWindow(title: event.title),
          onTap: () => _drawRoute(event.latitude, event.longitude),
        ),
      );
    }
  }

  Future<void> _getCurrentLocation() async {

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        handlePermissionDenial(context, "Location");
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      handlePermissionDenial(context, "Location");
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _currentLocationMarker = Marker(
        markerId: MarkerId("current_location"),
        position: _currentLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: "You are here"),
      );
      _markers.add(_currentLocationMarker!);
    });
  }

  List<LatLng> _decodePolyline(String encoded) {
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> result = polylinePoints.decodePolyline(encoded);

    return result.map((point) => LatLng(point.latitude, point.longitude)).toList();
  }

  Future<void> _drawRoute(double destLat, double destLng) async {
    if (_isFetchingRoute) return;
    _isFetchingRoute = true;

    try {
      if (_currentLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fetching current location...")),
        );
        _isFetchingRoute = false;
        return;
      }

      final String apiKey = 'AIzaSyBDr-OZednF2tDG5LqTpahZFzvPL4LucAk';
      final String url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=${_currentLocation!.latitude},${_currentLocation!.longitude}&destination=$destLat,$destLng&key=$apiKey';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'].isNotEmpty) {
          final points = _decodePolyline(data['routes'][0]['overview_polyline']['points']);
          final polyline = Polyline(
            polylineId: PolylineId("route_to_event"),
            color: Colors.blue,
            width: 5,
            points: points,
          );

          setState(() {
            _polylines.clear();
            _polylines.add(polyline);
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch directions: ${response.reasonPhrase}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching directions: $e")),
      );
    } finally {
      _isFetchingRoute = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Event Locations')),
      body: _currentLocation == null
        ? Center(child: CircularProgressIndicator())
            : GoogleMap(
        initialCameraPosition: CameraPosition(
        target: _currentLocation!,
        zoom: 14,
        ),
        markers: _markers,
        polylines: _polylines,
        onMapCreated: (controller) => _mapController = controller,
      ),
    );
  }
}

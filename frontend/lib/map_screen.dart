// lib/map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LocationData? _currentLocation;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        setState(() => _error = "Location services are disabled.");
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        setState(() => _error = "Location permission denied.");
        return;
      }
    }

    // Get initial location
    final initialLocation = await location.getLocation();
    setState(() {
      _currentLocation = initialLocation;
    });

    // Listen for live location updates
    location.onLocationChanged.listen((LocationData newLocation) {
      if (mounted) {
        setState(() {
          _currentLocation = newLocation;
          _mapController.move(
            LatLng(newLocation.latitude!, newLocation.longitude!),
            15.0,
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_error != null) {
      body = Center(child: Text('Error: $_error'));
    } else if (_currentLocation == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              Marker(
                width: 80.0,
                height: 80.0,
                point: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
                child: const Icon(Icons.my_location, color: Colors.blueAccent, size: 40.0),
              ),
            ],
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Location'),
      ),
      body: body,
    );
  }
}
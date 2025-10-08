// lib/map_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'auth_providers.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LocationData? _currentLocation;
  String? _error;
  List<Map<String, dynamic>> _incidents = [];
  bool _isLoadingIncidents = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    setState(() {
      _isLoadingIncidents = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final incidents = await authProvider.getIncidents();
      setState(() {
        _incidents = incidents;
        _isLoadingIncidents = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingIncidents = false;
      });
      print('Error loading incidents: $e');
    }
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

  List<Polygon> _buildIncidentPolygons() {
    List<Polygon> polygons = [];

    for (var incident in _incidents) {
      final details = incident['details'] as Map<String, dynamic>?;
      if (details != null && details['location'] is Map) {
        final location = details['location'] as Map<String, dynamic>;
        final lat = location['latitude'] as double?;
        final lng = location['longitude'] as double?;

        if (lat != null && lng != null) {
          // Create a small circular polygon around the incident location
          final center = LatLng(lat, lng);
          final radius = 0.0001; // Small radius for visibility

          // Generate points for a circle
          List<LatLng> circlePoints = [];
          for (int i = 0; i < 16; i++) {
            final angle = (i * 2 * 3.14159) / 16;
            final x = center.longitude + radius * cos(angle);
            final y = center.latitude + radius * sin(angle);
            circlePoints.add(LatLng(y, x));
          }

          // Determine color based on incident type
          Color polygonColor = _getIncidentColor(details['type'] as String?);

          polygons.add(
            Polygon(
              points: circlePoints,
              color: polygonColor.withOpacity(0.3),
              borderColor: polygonColor,
              borderStrokeWidth: 2.0,
              isFilled: true,
            ),
          );
        }
      }
    }

    return polygons;
  }

  List<Marker> _buildIncidentMarkers() {
    List<Marker> markers = [];

    for (int i = 0; i < _incidents.length; i++) {
      final incident = _incidents[i];
      final details = incident['details'] as Map<String, dynamic>?;

      if (details != null && details['location'] is Map) {
        final location = details['location'] as Map<String, dynamic>;
        final lat = location['latitude'] as double?;
        final lng = location['longitude'] as double?;

        if (lat != null && lng != null) {
          final incidentType = details['type'] as String? ?? 'Unknown';
          final incidentDate = incident['created_at'] as String? ?? '';

          markers.add(
            Marker(
              width: 40.0,
              height: 40.0,
              point: LatLng(lat, lng),
              child: GestureDetector(
                onTap: () =>
                    _showIncidentInfo(incidentType, incidentDate, details),
                child: Container(
                  decoration: BoxDecoration(
                    color: _getIncidentColor(incidentType),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getIncidentIcon(incidentType),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    return markers;
  }

  Color _getIncidentColor(String? incidentType) {
    switch (incidentType?.toLowerCase()) {
      case 'theft':
        return Colors.red;
      case 'assault':
        return Colors.purple;
      case 'robbery':
        return Colors.deepOrange;
      case 'vandalism':
        return Colors.orange;
      case 'harassment':
        return Colors.pink;
      case 'accident':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData _getIncidentIcon(String? incidentType) {
    switch (incidentType?.toLowerCase()) {
      case 'theft':
        return Icons.shopping_bag;
      case 'assault':
        return Icons.warning;
      case 'robbery':
        return Icons.security;
      case 'vandalism':
        return Icons.build;
      case 'harassment':
        return Icons.person_off;
      case 'accident':
        return Icons.car_crash;
      default:
        return Icons.report_problem;
    }
  }

  void _showIncidentInfo(
    String incidentType,
    String incidentDate,
    Map<String, dynamic> details,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Incident: $incidentType'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: ${_formatDate(incidentDate)}'),
              const SizedBox(height: 8),
              Text(
                'Description: ${details['description'] ?? 'No description'}',
              ),
              if (details['location'] is Map) ...[
                const SizedBox(height: 8),
                Text(
                  'Location: ${details['location']['latitude']?.toStringAsFixed(6)}, ${details['location']['longitude']?.toStringAsFixed(6)}',
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
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
          initialCenter: LatLng(
            _currentLocation!.latitude!,
            _currentLocation!.longitude!,
          ),
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          // Incident polygons layer
          PolygonLayer(polygons: _buildIncidentPolygons()),
          // Current location marker
          MarkerLayer(
            markers: [
              Marker(
                width: 80.0,
                height: 80.0,
                point: LatLng(
                  _currentLocation!.latitude!,
                  _currentLocation!.longitude!,
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Colors.blueAccent,
                  size: 40.0,
                ),
              ),
            ],
          ),
          // Incident markers
          MarkerLayer(markers: _buildIncidentMarkers()),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Location'),
        actions: [
          IconButton(
            onPressed: _loadIncidents,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh incidents',
          ),
        ],
      ),
      body: Stack(
        children: [
          body,
          if (_isLoadingIncidents)
            const Positioned(
              top: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Loading incidents...'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

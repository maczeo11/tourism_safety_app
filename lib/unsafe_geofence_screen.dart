import 'dart:async';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'auth_providers.dart';
import 'notification_service.dart';

class UnsafeGeofenceScreen extends StatefulWidget {
  const UnsafeGeofenceScreen({super.key});

  @override
  State<UnsafeGeofenceScreen> createState() => _UnsafeGeofenceScreenState();
}

class _UnsafeGeofenceScreenState extends State<UnsafeGeofenceScreen> {
  final Location _location = Location();
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<LocationData>? _sub;
  String? _error;
  bool _monitoring = false;
  String _status = 'Not monitoring';
  List<Map<String, dynamic>> _incidents = [];
  Set<String> _notifiedIncidents =
      {}; // Track which incidents we've already notified about
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
    _checkNotificationPermissions();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _loadIncidents() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final incidents = await authProvider.getIncidents();
      setState(() {
        _incidents = incidents;
      });
    } catch (e) {
      print('Error loading incidents: $e');
    }
  }

  Future<void> _checkNotificationPermissions() async {
    final hasPermission = await _notificationService.requestPermissions();
    setState(() {
      _notificationsEnabled = hasPermission;
    });
  }

  Future<void> _toggleMonitoring() async {
    if (_monitoring) {
      await _sub?.cancel();
      setState(() {
        _monitoring = false;
        _status = 'Not monitoring';
      });
      return;
    }

    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          setState(() => _error = 'Location services are disabled.');
          return;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          setState(() => _error = 'Location permission denied.');
          return;
        }
      }

      _sub = _location.onLocationChanged.listen((loc) {
        if (loc.latitude == null || loc.longitude == null) return;
        final user = LatLng(loc.latitude!, loc.longitude!);
        _checkNearbyIncidents(user);
      });

      setState(() {
        _monitoring = true;
        _status = 'Monitoring started';
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  void _checkNearbyIncidents(LatLng userLocation) {
    final distance = const Distance();
    bool nearIncident = false;
    String nearestIncidentType = '';
    double nearestDistance = double.infinity;

    for (var incident in _incidents) {
      final details = incident['details'] as Map<String, dynamic>?;
      if (details != null && details['location'] is Map) {
        final location = details['location'] as Map<String, dynamic>;
        final lat = location['latitude'] as double?;
        final lng = location['longitude'] as double?;

        if (lat != null && lng != null) {
          final incidentLocation = LatLng(lat, lng);
          final incidentDistance = distance(userLocation, incidentLocation);

          // Check if within 200 meters of an incident
          if (incidentDistance <= 200) {
            nearIncident = true;
            final incidentId = incident['id'].toString();
            final incidentType = details['type'] as String? ?? 'Unknown';

            // Only notify once per incident
            if (!_notifiedIncidents.contains(incidentId)) {
              _notifiedIncidents.add(incidentId);

              if (_notificationsEnabled) {
                _notificationService.showIncidentAlert(
                  incidentType: incidentType,
                  description:
                      details['description'] as String? ?? 'No description',
                  distance: incidentDistance,
                );
              }

              _showAlert(incidentType, incidentDistance);
            }

            if (incidentDistance < nearestDistance) {
              nearestDistance = incidentDistance;
              nearestIncidentType = incidentType;
            }
          }
        }
      }
    }

    setState(() {
      _status = nearIncident
          ? '⚠️ Near incident location ($nearestIncidentType - ${nearestDistance.toStringAsFixed(0)}m)'
          : '✅ Safe - No nearby incidents';
    });
  }

  void _showAlert(String incidentType, double distance) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '⚠️ You are near a $incidentType incident location (${distance.toStringAsFixed(0)}m away)',
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unsafe Location - Geofencing')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🚨 Incident Alert System',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This feature monitors your location and alerts you when you\'re near locations where incidents have been reported.',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Incidents loaded: ${_incidents.length}',
                      style: TextStyle(
                        color: _incidents.isEmpty
                            ? Colors.orange
                            : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notification permission status
            Card(
              color: _notificationsEnabled
                  ? Colors.green[50]
                  : Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(
                      _notificationsEnabled
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      color: _notificationsEnabled
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _notificationsEnabled
                            ? 'Notifications enabled - You\'ll receive alerts when near incidents'
                            : 'Notifications disabled - Enable for full safety alerts',
                        style: TextStyle(
                          color: _notificationsEnabled
                              ? Colors.green[700]
                              : Colors.orange[700],
                        ),
                      ),
                    ),
                    if (!_notificationsEnabled)
                      TextButton(
                        onPressed: _checkNotificationPermissions,
                        child: const Text('Enable'),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (_error != null)
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Status display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _status.contains('⚠️')
                    ? Colors.red[50]
                    : Colors.green[50],
                border: Border.all(
                  color: _status.contains('⚠️') ? Colors.red : Colors.green,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _status.contains('⚠️') ? Icons.warning : Icons.check_circle,
                    color: _status.contains('⚠️') ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Status: $_status',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: _status.contains('⚠️')
                            ? Colors.red[700]
                            : Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _toggleMonitoring,
                    icon: Icon(_monitoring ? Icons.stop : Icons.play_arrow),
                    label: Text(
                      _monitoring ? 'Stop Monitoring' : 'Start Monitoring',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _monitoring ? Colors.red : Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _loadIncidents,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh incidents',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

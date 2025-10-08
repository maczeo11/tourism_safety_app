// lib/report_incident_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';
import 'package:latlong2/latlong.dart';
import 'auth_providers.dart';
import 'location_picker_screen.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  _ReportIncidentScreenState createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _typeController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  LocationData? _currentLocation;
  LatLng? _selectedLocation;
  String? _locationError;
  final Location _location = Location();
  bool _useSelectedLocation =
      false; // false = use current location, true = use selected location

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          setState(() {
            _locationError = 'Location services are disabled.';
          });
          return;
        }
      }

      // Check location permissions
      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          setState(() {
            _locationError = 'Location permission denied.';
          });
          return;
        }
      }

      // Get current location
      final locationData = await _location.getLocation();
      setState(() {
        _currentLocation = locationData;
        _locationError = null;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Failed to get location: ${e.toString()}';
      });
    }
  }

  Future<void> _selectLocationOnMap() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
        _useSelectedLocation = true;
      });
    }
  }

  void _useCurrentLocation() {
    setState(() {
      _useSelectedLocation = false;
      _selectedLocation = null;
    });
  }

  Color _getLocationStatusColor() {
    if (_useSelectedLocation) {
      return _selectedLocation != null ? Colors.green[50]! : Colors.orange[50]!;
    } else {
      return _currentLocation != null ? Colors.green[50]! : Colors.orange[50]!;
    }
  }

  Color _getLocationStatusBorderColor() {
    if (_useSelectedLocation) {
      return _selectedLocation != null ? Colors.green : Colors.orange;
    } else {
      return _currentLocation != null ? Colors.green : Colors.orange;
    }
  }

  IconData _getLocationStatusIcon() {
    if (_useSelectedLocation) {
      return _selectedLocation != null ? Icons.location_on : Icons.location_off;
    } else {
      return _currentLocation != null ? Icons.location_on : Icons.location_off;
    }
  }

  String _getLocationStatusText() {
    if (_useSelectedLocation) {
      return _selectedLocation != null
          ? 'Custom location selected'
          : 'No location selected';
    } else {
      return _currentLocation != null
          ? 'Using current location'
          : 'Location not available';
    }
  }

  String? _getLocationCoordinates() {
    if (_useSelectedLocation && _selectedLocation != null) {
      return 'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
          'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}';
    } else if (!_useSelectedLocation && _currentLocation != null) {
      return 'Lat: ${_currentLocation!.latitude?.toStringAsFixed(6) ?? 'N/A'}, '
          'Lng: ${_currentLocation!.longitude?.toStringAsFixed(6) ?? 'N/A'}';
    }
    return null;
  }

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Prepare location data
      Map<String, dynamic> locationData = {};
      String locationStatus = 'unavailable';

      if (_useSelectedLocation && _selectedLocation != null) {
        locationData = {
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
          'accuracy': 0.0, // Map selected location has no accuracy
          'timestamp': DateTime.now().toIso8601String(),
          'source': 'map_selection',
        };
        locationStatus = 'available';
      } else if (!_useSelectedLocation && _currentLocation != null) {
        locationData = {
          'latitude': _currentLocation!.latitude,
          'longitude': _currentLocation!.longitude,
          'accuracy': _currentLocation!.accuracy,
          'timestamp': DateTime.now().toIso8601String(),
          'source': 'gps',
        };
        locationStatus = 'available';
      }

      final incidentDetails = {
        'type': _typeController.text,
        'description': _descriptionController.text,
        'location': locationData.isNotEmpty
            ? locationData
            : 'Location not available',
        'location_status': locationStatus,
      };

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.reportIncident(incidentDetails);

      if (mounted) {
        final message = success
            ? 'Incident reported successfully!'
            : (authProvider.errorMessage ?? 'Failed to report incident.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) {
          Navigator.of(context).pop();
        }
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report an Incident')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(
                  labelText: 'Type of Incident (e.g., Theft)',
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a type' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),
              // Location status display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getLocationStatusColor(),
                  border: Border.all(
                    color: _getLocationStatusBorderColor(),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getLocationStatusIcon(),
                          color: _getLocationStatusBorderColor(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getLocationStatusText(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getLocationStatusBorderColor(),
                                ),
                              ),
                              if (_getLocationCoordinates() != null) ...[
                                Text(
                                  _getLocationCoordinates()!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getLocationStatusBorderColor(),
                                  ),
                                ),
                              ] else if (_locationError != null &&
                                  !_useSelectedLocation) ...[
                                Text(
                                  _locationError!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (_useSelectedLocation)
                          IconButton(
                            onPressed: _selectLocationOnMap,
                            icon: const Icon(Icons.map),
                            tooltip: 'Change location on map',
                          )
                        else if (_currentLocation == null &&
                            _locationError != null)
                          IconButton(
                            onPressed: _getCurrentLocation,
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Retry location',
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Action buttons
                    Row(
                      children: [
                        if (!_useSelectedLocation) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectLocationOnMap,
                              icon: const Icon(Icons.map, size: 18),
                              label: const Text('Select Different Location'),
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _useCurrentLocation,
                              icon: const Icon(Icons.my_location, size: 18),
                              label: const Text('Use Current Location'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectLocationOnMap,
                              icon: const Icon(Icons.map, size: 18),
                              label: const Text('Change Location'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitReport,
                      child: const Text('Submit Report'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

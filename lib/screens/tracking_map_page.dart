import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/location_tracking_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class TrackingMapPage extends StatefulWidget {
  final String requestId;
  final String travelerName;
  final String serviceType;
  final String status;

  const TrackingMapPage({
    super.key,
    required this.requestId,
    required this.travelerName,
    required this.serviceType,
    required this.status,
  });

  @override
  State<TrackingMapPage> createState() => _TrackingMapPageState();
}

class _TrackingMapPageState extends State<TrackingMapPage> {
  final LocationTrackingService _trackingService = LocationTrackingService();
  GoogleMapController? _mapController;
  RealtimeChannel? _locationChannel;

  LatLng? _travelerLocation;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadInitialLocation();
    _subscribeToLocationUpdates();
  }

  @override
  void dispose() {
    _trackingService.unsubscribeFromLocation();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadInitialLocation() async {
    try {
      final location = await _trackingService.getCurrentLocation(
        widget.requestId,
      );

      if (location != null && mounted) {
        setState(() {
          _travelerLocation = LatLng(
            location['latitude']!,
            location['longitude']!,
          );
          _updateMarkers();
          _isLoading = false;
        });

        // Move camera to traveler location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_travelerLocation!, 15),
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Traveler location not available yet';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading location: $e';
      });
    }
  }

  void _subscribeToLocationUpdates() {
    _locationChannel = _trackingService.subscribeToLocation(widget.requestId, (
      lat,
      lng,
    ) {
      if (mounted) {
        setState(() {
          _travelerLocation = LatLng(lat, lng);
          _updateMarkers();
        });

        // Smoothly move camera to new location
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(_travelerLocation!),
        );
      }
    });
  }

  void _updateMarkers() {
    if (_travelerLocation == null) return;

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('traveler'),
          position: _travelerLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          flat: true,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: widget.travelerName,
            snippet: 'On the way',
          ),
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Track ${widget.travelerName}',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16 * scaleFactor,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.serviceType,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12 * scaleFactor,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Google Map
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16 * scaleFactor,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = '';
                        });
                        _loadInitialLocation();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else
            GoogleMap(
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              initialCameraPosition: CameraPosition(
                target:
                    _travelerLocation ??
                    const LatLng(10.7202, 122.5621), // Default to Iloilo
                zoom: 15,
              ),
              markers: _markers,
              zoomControlsEnabled: true,
              mapType: MapType.normal,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                if (_travelerLocation != null) {
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(_travelerLocation!, 15),
                  );
                }
              },
            ),

          // Status card at bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: EdgeInsets.all(20 * scaleFactor),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16 * scaleFactor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8 * scaleFactor),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8 * scaleFactor),
                        ),
                        child: Icon(
                          Icons.local_shipping_outlined,
                          color: AppConstants.primaryColor,
                          size: 24 * scaleFactor,
                        ),
                      ),
                      SizedBox(width: 12 * scaleFactor),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.travelerName,
                              style: TextStyle(
                                fontSize: 16 * scaleFactor,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 4 * scaleFactor),
                            Row(
                              children: [
                                Container(
                                  width: 8 * scaleFactor,
                                  height: 8 * scaleFactor,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 6 * scaleFactor),
                                Text(
                                  widget.status,
                                  style: TextStyle(
                                    fontSize: 13 * scaleFactor,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12 * scaleFactor),
                  Container(
                    padding: EdgeInsets.all(12 * scaleFactor),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8 * scaleFactor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16 * scaleFactor,
                          color: Colors.blue[700],
                        ),
                        SizedBox(width: 8 * scaleFactor),
                        Expanded(
                          child: Text(
                            'Traveler\'s location updates in real-time',
                            style: TextStyle(
                              fontSize: 12 * scaleFactor,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

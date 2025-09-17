// bloc/delivery_bloc.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:reciever/constants.dart';

import 'location_event.dart';
import 'location_state.dart';



class DeliveryBloc extends Bloc<DeliveryEvent, DeliveryState> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("user_location");
  StreamSubscription<DatabaseEvent>? _subscription;
  StreamSubscription<Position>? _locationSubscription;
  List<LatLng> _routePolyline = [];

  DeliveryBloc() : super(const DeliveryState()) {
    on<DeliveryStarted>(_onDeliveryStarted);
    on<DriverLocationUpdated>(_onDriverLocationUpdated);
    on<UserLocationUpdated>(_onUserLocationUpdated);
    on<MapCreated>(_onMapCreated);
    on<CenterOnDriverRequested>(_onCenterOnDriverRequested);
    on<CenterOnUserRequested>(_onCenterOnUserRequested);
  }

  Future<void> _onDeliveryStarted(
      DeliveryStarted event,
      Emitter<DeliveryState> emit,
      ) async {
    await _initializeLocation();
    _startListeningToDriver();
  }

  Future<void> _onDriverLocationUpdated(
      DriverLocationUpdated event,
      Emitter<DeliveryState> emit,
      ) async {
    emit(state.copyWith(
      driverLocation: event.location,
      isLoading: state.userLocation == null,
    ));

    if (state.userLocation != null) {
      await _updateRoutePolyline(event.location, state.userLocation!, emit);
      await _calculateDistanceAndETA(event.location, state.userLocation!, emit);
    }

    _updateMapOverlays(emit);
  }

  Future<void> _onUserLocationUpdated(
      UserLocationUpdated event,
      Emitter<DeliveryState> emit,
      ) async {
    emit(state.copyWith(
      userLocation: event.location,
      isLoading: state.driverLocation == null,
    ));

    if (state.driverLocation != null) {
      await _updateRoutePolyline(state.driverLocation!, event.location, emit);
      await _calculateDistanceAndETA(state.driverLocation!, event.location, emit);
    }

    _updateMapOverlays(emit);
  }

  void _onMapCreated(MapCreated event, Emitter<DeliveryState> emit) {
    emit(state.copyWith(mapController: event.controller));
  }

  void _onCenterOnDriverRequested(
      CenterOnDriverRequested event,
      Emitter<DeliveryState> emit,
      ) {
    if (state.driverLocation != null && state.mapController != null) {
      state.mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: state.driverLocation!,
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  void _onCenterOnUserRequested(
      CenterOnUserRequested event,
      Emitter<DeliveryState> emit,
      ) {
    if (state.userLocation != null && state.mapController != null) {
      state.mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: state.userLocation!,
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  // Location and Firebase methods (similar to your original service)
  Future<void> _initializeLocation() async {
    try {
      final status = await Permission.location.request();

      if (status.isGranted) {
        final position = await Geolocator.getCurrentPosition();
        add(UserLocationUpdated(LatLng(position.latitude, position.longitude)));

        final LocationSettings locationSettings = LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5,
        );

        _locationSubscription = Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen((Position position) {
          add(UserLocationUpdated(LatLng(position.latitude, position.longitude)));
        });
      } else {
        print('❌ Location permission denied');
      }
    } catch (e) {
      print('❌ Error getting location: $e');
    }
  }

  void _startListeningToDriver() {
    _subscription = _dbRef.child("user1").onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value;
        if (data is Map<dynamic, dynamic>) {
          _processDriverLocation(data);
        }
      }
    }, onError: (error) {
      print('❌ Firebase Error: $error');
    });
  }

  void _processDriverLocation(Map<dynamic, dynamic> data) {
    try {
      if (data['latitude'] == null || data['longitude'] == null) return;

      final double lat = double.parse(data['latitude'].toString());
      final double lng = double.parse(data['longitude'].toString());

      add(DriverLocationUpdated(LatLng(lat, lng)));
    } catch (e) {
      print('❌ Error processing driver location: $e');
    }
  }

  Future<void> _updateRoutePolyline(
      LatLng driverLocation,
      LatLng userLocation,
      Emitter<DeliveryState> emit,
      ) async {
    try {
      final String apiKey = Constant.apikey;
      final String url =
          'https://maps.googleapis.com/maps/api/directions/json?' +
              'origin=${driverLocation.latitude},${driverLocation.longitude}' +
              '&destination=${userLocation.latitude},${userLocation.longitude}' +
              '&mode=driving&key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final List<dynamic> routes = data['routes'];
          if (routes.isNotEmpty) {
            final dynamic route = routes[0];
            final dynamic overviewPolyline = route['overview_polyline'];
            final String points = overviewPolyline['points'];

            _routePolyline = _decodePolyline(points);
            return;
          }
        }
      }

      // Fallback
      _routePolyline = [driverLocation, userLocation];
    } catch (e) {
      print('❌ Error getting route: $e');
      _routePolyline = [driverLocation, userLocation];
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    // Same implementation as before
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  void _updateMapOverlays(Emitter<DeliveryState> emit) {
    final polylines = <Polyline>{};
    if (_routePolyline.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('delivery_route'),
          points: _routePolyline,
          color: Colors.blue,
          width: 5,
          geodesic: true,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    }

    final markers = <Marker>{};

    if (state.driverLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: state.driverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Delivery Partner'),
          rotation: _calculateBearing(),
        ),
      );
    }

    if (state.userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: state.userLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    emit(state.copyWith(markers: markers, polylines: polylines));
  }

  Future<void> _calculateDistanceAndETA(
      LatLng driverLocation,
      LatLng userLocation,
      Emitter<DeliveryState> emit,
      ) async {
    try {
      final String apiKey =Constant.apikey;
      final String url =
          'https://maps.googleapis.com/maps/api/distancematrix/json?' +
              'origins=${driverLocation.latitude},${driverLocation.longitude}' +
              '&destinations=${userLocation.latitude},${userLocation.longitude}' +
              '&mode=driving&key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' &&
            data['rows'][0]['elements'][0]['status'] == 'OK') {

          final distanceText = data['rows'][0]['elements'][0]['distance']['text'];
          final durationText = data['rows'][0]['elements'][0]['duration']['text'];

          emit(state.copyWith(
            distanceText: distanceText,
            durationText: durationText,
          ));
        }
      }
    } catch (e) {
      print('❌ Error calculating distance: $e');
    }
  }

  double _calculateBearing() {
    if (state.driverLocation == null || state.userLocation == null) return 0;

    final startLat = _toRadians(state.driverLocation!.latitude);
    final startLng = _toRadians(state.driverLocation!.longitude);
    final endLat = _toRadians(state.userLocation!.latitude);
    final endLng = _toRadians(state.userLocation!.longitude);

    final y = math.sin(endLng - startLng) * math.cos(endLat);
    final x = math.cos(startLat) * math.sin(endLat) -
        math.sin(startLat) * math.cos(endLat) * math.cos(endLng - startLng);

    final bearing = math.atan2(y, x);
    return bearing * 180 / math.pi;
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _locationSubscription?.cancel();
    return super.close();
  }
}
// states/delivery_state.dart


import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

@immutable
class DeliveryState extends Equatable {
  final LatLng? driverLocation;
  final LatLng? userLocation;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final String distanceText;
  final String durationText;
  final bool isLoading;
  final GoogleMapController? mapController;

  const DeliveryState({
    this.driverLocation,
    this.userLocation,
    this.markers = const {},
    this.polylines = const {},
    this.distanceText = "Calculating...",
    this.durationText = "",
    this.isLoading = true,
    this.mapController,
  });

  DeliveryState copyWith({
    LatLng? driverLocation,
    LatLng? userLocation,
    Set<Marker>? markers,
    Set<Polyline>? polylines,
    String? distanceText,
    String? durationText,
    bool? isLoading,
    GoogleMapController? mapController,
  }) {
    return DeliveryState(
      driverLocation: driverLocation ?? this.driverLocation,
      userLocation: userLocation ?? this.userLocation,
      markers: markers ?? this.markers,
      polylines: polylines ?? this.polylines,
      distanceText: distanceText ?? this.distanceText,
      durationText: durationText ?? this.durationText,
      isLoading: isLoading ?? this.isLoading,
      mapController: mapController ?? this.mapController,
    );
  }

  @override
  List<Object?> get props => [
    driverLocation,
    userLocation,
    markers,
    polylines,
    distanceText,
    durationText,
    isLoading,
    mapController,
  ];
}
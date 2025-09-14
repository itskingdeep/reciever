import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class LocationState extends Equatable {
  const LocationState();
  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {}

class LocationUpdated extends LocationState {
  final List<LatLng> polylineCoordinates;
  final LatLng currentPosition;

  const LocationUpdated({
    required this.polylineCoordinates,
    required this.currentPosition,
  });

  @override
  List<Object?> get props => [polylineCoordinates, currentPosition];
}

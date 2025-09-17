// events/delivery_events.dart


import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


@immutable
abstract class DeliveryEvent extends Equatable {
  const DeliveryEvent();

  @override
  List<Object?> get props => [];
}

class DeliveryStarted extends DeliveryEvent {}

class DriverLocationUpdated extends DeliveryEvent {
  final LatLng location;

  const DriverLocationUpdated(this.location);

  @override
  List<Object?> get props => [location];
}

class UserLocationUpdated extends DeliveryEvent {
  final LatLng location;

  const UserLocationUpdated(this.location);

  @override
  List<Object?> get props => [location];
}

class MapCreated extends DeliveryEvent {
  final GoogleMapController controller;

  const MapCreated(this.controller);

  @override
  List<Object?> get props => [controller];
}

class CenterOnDriverRequested extends DeliveryEvent {}

class CenterOnUserRequested extends DeliveryEvent {}
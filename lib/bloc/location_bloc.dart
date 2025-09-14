import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'location_event.dart';
import 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref("user_location/user1");
  StreamSubscription<DatabaseEvent>? _subscription;
  final List<LatLng> _polylineCoordinates = [];

  LocationBloc() : super(LocationInitial()) {
    on<StartListeningLocation>((event, emit) {
      _subscription = dbRef.onValue.listen((snapshot) {
        try {
          if (snapshot.snapshot.exists) {
            final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
            double lat = double.parse(data['latitude'].toString());
            double lng = double.parse(data['longitude'].toString());
            LatLng newPosition = LatLng(lat, lng);

            _polylineCoordinates.add(newPosition);

            emit(LocationUpdated(
              polylineCoordinates: List.from(_polylineCoordinates),
              currentPosition: newPosition,
            ));
          }
        } catch (e) {
          print("Error parsing Firebase data: $e");
          // Optional: emit error state if you create one
        }
      }, onError: (error) {
        print("Firebase listener error: $error");
      });

    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

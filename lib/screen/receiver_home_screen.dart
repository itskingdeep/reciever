import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../bloc/location_bloc.dart';
import '../bloc/location_state.dart';

class ReceiverHomeScreen extends StatelessWidget {
  const ReceiverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    GoogleMapController? mapController;

    return Scaffold(
      appBar: AppBar(title: const Text("Receiver App")),
      body: BlocBuilder<LocationBloc, LocationState>(
        builder: (context, state) {
          Set<Polyline> polylines = {};
          Set<Marker> markers = {};
          LatLng initialPosition = const LatLng(28.6139, 77.2090);

          if (state is LocationUpdated && state.polylineCoordinates.isNotEmpty) {
            initialPosition = state.currentPosition;

            polylines.add(Polyline(
              polylineId: const PolylineId("route"),
              points: state.polylineCoordinates,
              width: 5,
              color: Colors.blue,
            ));

            markers.add(Marker(
              markerId: const MarkerId("current"),
              position: state.polylineCoordinates.last,
            ));

            // Animate camera to latest position
            WidgetsBinding.instance.addPostFrameCallback((_) {
              mapController?.animateCamera(
                CameraUpdate.newLatLng(initialPosition),
              );
            });
          }

          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: 15,
            ),
            polylines: polylines,
            markers: markers,
            onMapCreated: (controller) {
              mapController = controller;
            },
          );
        },
      ),
    );
  }
}

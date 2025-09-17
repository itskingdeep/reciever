import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reciever/screen/delivery_map_screen.dart';

import 'bloc/location_bloc.dart'; // Import your BLoC

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DeliveryBloc(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Delivery Tracker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const DeliveryMapScreen(),
      ),
    );
  }
}
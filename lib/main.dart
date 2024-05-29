import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart' as loc;
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyBcA4klUGzIamW7PC-nERoW9zcEVCWjLfg",
            //metaxperts apiKey: "AIzaSyDWoxlTqTARPPm-dk0AL6JN1kJwWksDpro",
            authDomain: "courage-erp.firebaseapp.com",
            projectId: "courage-erp",
            storageBucket: "courage-erp.appspot.com",
            messagingSenderId: "298934362650",
            appId: "1:298934362650:web:dbc179a4e4582af124a7a3",
            measurementId: "G-YF6KQXMBZK"
        )
    );
        // Awais Farooq Firebase Configuration
        // await Firebase.initializeApp(
    //     options: const FirebaseOptions(
    //         apiKey: "AIzaSyBcA4klUGzIamW7PC-nERoW9zcEVCWjLfg",
    //         authDomain: "location-e5cc0.firebaseapp.com",
    //         projectId: "location-e5cc0",
    //         storageBucket: "location-e5cc0.appspot.com",
    //         messagingSenderId: "132021888954",
    //         appId: "1:132021888954:web:9a8e12d10f6b4b1c93df83"
    //     )
    // );

    if (kDebugMode) {
      print("Initialize is OK");
    }
  } catch(e) {
    if (kDebugMode) {
      print("Initialize failed: $e");
    }
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Maps Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Dashboard("id_here"),
    );
  }
}

class Dashboard extends StatefulWidget {
  final String user_id;

  Dashboard(this.user_id);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with WidgetsBindingObserver {
  late loc.Location location;
  late GoogleMapController _controller;
  bool _added = false;
  StreamSubscription<loc.LocationData>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    fetchData();
    location = loc.Location();
    WidgetsBinding.instance!.addObserver(this);
    _initLocationTracking();
  }

  void _initLocationTracking() {
    _locationSubscription = location.onLocationChanged.listen(
          (loc.LocationData currentLocation) {
        if (_added) {
          _updateMarkerPosition(currentLocation.latitude!, currentLocation.longitude!);
        }
      },
    );
  }
  @override
  void dispose() {
    _locationSubscription?.cancel();
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  void _updateMarkerPosition(double latitude, double longitude) async {
    await _controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(latitude, longitude),
          zoom: 14.47,
        ),
      ),
    );
  }
  Future<QuerySnapshot> fetchData() async {
    return await FirebaseFirestore.instance.collection('location').get();
  }

  Set<Marker> _createMarkersFromData(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

      String name = data != null && data.containsKey('name') ? data['name'] : 'Unknown';
      String designation = data != null && data.containsKey('designation') ? data['designation'] : 'Unknown';
      String city = data != null && data.containsKey('city') ? data['city'] : 'Unknown';

      return Marker(
        markerId: MarkerId(doc.id),
        position: LatLng(data!['latitude'], data['longitude']),
        infoWindow: InfoWindow(
          title: 'Name: $name\nDesignation: $designation\nCity: $city',
        ),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('location').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Image(
                    width: 600,
                    height: 400,
                    image: AssetImage(
                        'assets/no6-unscreen.gif'
                    )),
                // Icon(
                // Icons.warning,
                // color: Colors.red,
                // size: 50,
                // ),
                // SizedBox(height: 3),
                Text(
                    'There is no Active User',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.grey.shade500,  fontWeight: FontWeight.bold,
                    )
                ),
              ],

            ),

          );
        }

        var markers = _createMarkersFromData(snapshot.data!);
        var firstMarker = markers.first;
        return GoogleMap(
          mapType: MapType.normal,
          markers: markers,
          initialCameraPosition: CameraPosition(
            target: firstMarker.position,
            zoom: 13,
          ),
          onMapCreated: (GoogleMapController controller) {
            _controller = controller;
          },
        );
      },
    );
  }
}
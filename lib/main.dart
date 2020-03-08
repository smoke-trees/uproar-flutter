import 'dart:async';

import 'dart:io' show Platform;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';

//void main() => runApp(MyApp());

//class MyApp extends StatelessWidget {
//  @override
//  Widget build(BuildContext context) {
//    return MaterialApp(
//      debugShowCheckedModeBanner: false,
//      title: 'Flutter Google Maps Demo',
//      home: MapSample(username: "Pranjal"),
//    );
//  }
//}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final FirebaseApp app = await FirebaseApp.configure(
    name: 'riot',
    options: Platform.isIOS
        ? const FirebaseOptions(
            googleAppID: '1:25558707067:web:b3d65c743d247620bb6bde',
            gcmSenderID: '25558707067',
            databaseURL: "https://riot-270417.firebaseio.com",
          )
        : const FirebaseOptions(
            googleAppID: '1:25558707067:web:b3d65c743d247620bb6bde',
            apiKey: "AIzaSyC9VNVUGEp8JBegcys44Zp5bNZsjxGEuUk",
            databaseURL: "https://riot-270417.firebaseio.com",
          ),
  );
  runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Google Maps Demo',
      home: MapSample(
        username: "pranjalsrv",
        app: app,
      )));
}

class MapSample extends StatefulWidget {
  final String username;
  final FirebaseApp app;

  const MapSample({Key key, this.username, this.app}) : super(key: key);

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  Completer<GoogleMapController> _controller = Completer();
  List<Marker> allMarkers = [];
  final _sosMessageController = TextEditingController();
  var isSOSvisible = true;
  Position position = Position();

  DatabaseReference _messagesRef;
  var _netDistressReference;
  StreamSubscription<Event> _messagesSubscription;
  DatabaseError _error;

  @override
  void initState() {
    super.initState();
    // TODO: Get all markers here
    // Demonstrates configuring to the database using a file
    _netDistressReference = FirebaseDatabase.instance.reference();
    // Demonstrates configuring the database directly
    final FirebaseDatabase database = FirebaseDatabase(app: widget.app);
    _messagesRef = database.reference().child('net_distress');
    database.reference().child('counter').once().then((DataSnapshot snapshot) {
      print('Connected to second database and read ${snapshot.value}');
    });
    database.setPersistenceEnabled(true);
    database.setPersistenceCacheSizeBytes(10000000);
    _netDistressReference.keepSynced(true);
  }

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(20.5937, 78.9629),
    zoom: 5,
  );

  @override
  Widget build(BuildContext context) {
    Widget SOSbuttun = isSOSvisible
        ? Container(
            margin: EdgeInsets.only(
                top: MediaQuery.of(context).size.height - 80,
                left: MediaQuery.of(context).size.width - 350),
            width: MediaQuery.of(context).size.width * .70,
            height: 65,
            child: FloatingActionButton.extended(
              backgroundColor: Colors.red,
              heroTag: "SOS",
              elevation: 10,
              onPressed: () {
                _goToTheLake();
                Future.delayed(const Duration(milliseconds: 500), () {
                  setState(() {
                    isSOSvisible = false;
                  });
                });
//            Navigator.push(context,
//                PageRouteBuilder(
//                    settings: RouteSettings(isInitialRoute: true),
//                    pageBuilder: (BuildContext context,
//                        Animation<double> animation,
//                        Animation<double> secondaryAnimation) =>
//                        CreatePlaylistPage()));
              },
              icon: Icon(Icons.add),
              label: Text(
                "SOS",
                style: TextStyle(fontSize: 20),
              ),
            ))
        : Hero(
            tag: "SOS",
            child: Container(
              margin: EdgeInsets.only(
                top: MediaQuery.of(context).size.height - 80,
              ),
              width: MediaQuery.of(context).size.width,
              height: 65,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: MediaQuery.of(context).size.width - 100,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Color(0xffe1e3e6)),
                    child: TextField(
                      style: TextStyle(color: Colors.blue, fontSize: 24),
                      controller: _sosMessageController,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: "SOS Message:",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.blue),
                    child: IconButton(
                      icon: Icon(Icons.send),
                      color: Colors.black,
                      onPressed: () {
                        print("sending ${_sosMessageController.text}");
                        //TODO: Send lat, long, msg to firebase
                        _netDistressReference
                            .child("net_distress")
                            .child(widget.username)
                            .set({
                          'latitude': position.latitude,
                          'longitude': position.longitude,
                          'message': _sosMessageController.text
                        });
                      },
                    ),
                  )
                ],
              ),
            ));

    return Scaffold(
      body: Center(
        child: Stack(
          children: <Widget>[
            Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: GoogleMap(
                markers: Set.from(allMarkers),
                mapType: MapType.normal,
                initialCameraPosition: _kGooglePlex,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
              ),
            ),
            //SOSbuttun               /////////////////////////
            SingleChildScrollView(
              child: Container(
                child: Stack(
                  children: <Widget>[
                    SOSbuttun
                    // your body code
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
//      floatingActionButton: FloatingActionButton.extended(
//        backgroundColor: Colors.red,
//        onPressed: _goToTheLake,
//        label: Text('SOS'),
//        icon: Icon(Icons.do_not_disturb_on),
//      ),
    );
  }

  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    print(position.latitude);
    print(position.longitude);
    final CameraPosition _currentPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        tilt: 59.440717697143555,
        zoom: 19.151926040649414);

    setState(() {
      allMarkers.add(Marker(
          position: LatLng(position.latitude, position.longitude),
          markerId: MarkerId(widget.username),
          onTap: () {
            Scaffold.of(context).showSnackBar(SnackBar(
              content: Text(widget.username),
            ));
          }));
    });

    controller.animateCamera(CameraUpdate.newCameraPosition(_currentPosition));
  }
}

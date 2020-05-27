import 'dart:async';

import 'dart:io' show Platform;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:intl/intl.dart';

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
        username: "anshu",
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
  static Completer<GoogleMapController> _controller = Completer();
  static List<Marker> allMarkers = [];
  List<String> usernames = [];
  final _sosMessageController = TextEditingController();
  var isSOSvisible = true;
  Position position = Position();
  Timer _timer;
  var uploadSuccess = false;

  DatabaseReference _netDistressReference;

  final snackBar = SnackBar(content: Text('Yay! A SnackBar!'));

  @override
  void initState() {
    super.initState();
    // TODO: Get all markers here
    // Demonstrates configuring to the database using a file
    _netDistressReference = FirebaseDatabase.instance.reference();
    // Demonstrates configuring the database directly
    final FirebaseDatabase database = FirebaseDatabase(app: widget.app);
    //_messagesRef = database.reference().child('net_distress');

    database.setPersistenceEnabled(true);
    //database.setPersistenceCacheSizeBytes(10000000);
    _netDistressReference.keepSynced(true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();

  }

  void _sendSMS(String message, List<String> recipents) async {
    try {
      String _result = await sendSMS(message: message, recipients: recipents);
      print(_result);
    } catch (error) {
      print(error.toString());
    }
  }

  void updateMarkers() {
    _netDistressReference
        .child('net_distress')
        .once()
        .then((DataSnapshot snapshot) {
//      snapshot.value.forEach((i, j) {
//        print("${i} has has ${i.runtimeType}");
//      });
      for (MapEntry entry in snapshot.value.entries) {
        var latitude;
        var longitude;
        var message;
        var username;
//        print("valueeees ${entry.key} says  ${entry.value}");
        username = entry.key;
        entry.value.forEach((i, j) {
          //print("${i}                       ${j}");
          if (i.toString() == 'latitude') {
            latitude = double.parse(j.toString());
          }
          if (i.toString() == 'longitude') {
            longitude = double.parse(j.toString());
          }
          if (i.toString() == 'message') {
            message = j.toString();
          }
        });

        if (!usernames.contains(username)) {
          allMarkers.add(Marker(
              markerId: MarkerId(username),
              position: LatLng(latitude, longitude),
              onTap: () {
                print(message);
              }));
          usernames.add(username);
        }

        //allMarkers.add(Marker(markerId: MarkerId(widget.username),position: LatLng(entry['latitude'],entry['longitude'])));
      }
      print("No. of points: ${allMarkers.length}");
    });
  }

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(20.5937, 78.9629),
    zoom: 5,
  );

  Widget Mapper() {
    return SafeArea(
      child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: GoogleMap(
            markers: Set.from(allMarkers),
            mapType: MapType.normal,
            initialCameraPosition: _kGooglePlex,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          )),
    );
  }

  void sendWithAndWithoutNet(
      double latitude, double longitude, String message) async {
    var connectivityResult = await (Connectivity().checkConnectivity());

    print(connectivityResult);
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      //print("sending ${_sosMessageController.text}");
      print("${latitude} ${longitude} ${message}");
      //TODO: Send lat, long, msg to firebase
      var now = new DateTime.now();
      String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);
      _netDistressReference.child("net_distress").child(widget.username).set({
        'latitude': latitude,
        'longitude': longitude,
        'message': message,
        'timestamp': formattedDate
      });
    } else {
      print("No net");
      _sendSMS(
          "Sending SMS to UpRoar...\n\nDON'T CHANGE THE MESSAGE BELOW!\n\nUsername: ___${widget.username}___\nLatitude: ___${latitude}___\nLongitude: ___${longitude}___\nMessage: ___${message}___\n\nDon't worry! We will reach out to you shortly!",
          ["+919004128000"]);  //+917014152658 anshu
    }
  }
  Widget customNotif() {
    return uploadSuccess
        ? Container(
        width: MediaQuery.of(context).size.width,
        color: Colors.red,
        height: 70,
        alignment: Alignment.bottomCenter,
        child: Container(
            padding: EdgeInsets.only(bottom: 3),
            child: Text(
              "Sent to UpRoar",
              style: TextStyle(fontSize: 20),
            )))
        : SizedBox.shrink();
  }


  @override
  Widget build(BuildContext context) {
    Widget SOSbutton = isSOSvisible
        ? Container(
        padding: EdgeInsets.all(10),
        width: MediaQuery.of(context).size.width*0.7,
        height: 80,
//            width: MediaQuery.of(context).size.width * .70,
//            height: 65,
        child: FloatingActionButton.extended(
          backgroundColor: Colors.red,
          heroTag: "SOS",
          elevation: 5,
          onPressed: () {
            _goToCurrentLocation();
            setState(() {
              isSOSvisible = false;
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
          width: MediaQuery.of(context).size.width,
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Padding(padding: EdgeInsets.only(left: 30),),
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
                ],
              ),
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.blue),
                child: IconButton(
                  icon: Icon(Icons.send),
                  color: Colors.black,
                  onPressed: () {
                    sendWithAndWithoutNet(position.latitude,
                        position.longitude, _sosMessageController.text);
                    uploadSuccess = true;
                    _timer =
                    new Timer(const Duration(milliseconds: 1000), () {
                      setState(() {
                        uploadSuccess = false;
                      });
                    });
                  },
                ),
              )
            ],
          ),
        ));

    return Scaffold(
      floatingActionButton: SOSbutton,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Center(
        child: Stack(
          children: <Widget>[
            Mapper(),
            customNotif(),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30), color: Colors.blue),
              margin: EdgeInsets.only(
                  top: 50, left: MediaQuery.of(context).size.width - 70),
              child: IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  setState(() {
                    updateMarkers();
                  });
                },
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

  Future<void> _goToCurrentLocation() async {
    final GoogleMapController controller = await _controller.future;
    position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best);

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
//            Scaffold.of(context).showSnackBar(SnackBar(
//              content: Text(widget.username),
//            ));
            print(widget.username);
            print(widget.username);
          }));
    });

    controller.animateCamera(CameraUpdate.newCameraPosition(_currentPosition));
  }
}

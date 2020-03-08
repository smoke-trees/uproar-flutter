import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Google Maps Demo',
      home: MapSample(username: "Pranjal"),
    );
  }
}

class MapSample extends StatefulWidget {
  final String username;

  const MapSample({Key key, this.username}) : super(key: key);

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  Completer<GoogleMapController> _controller = Completer();
  List<Marker> allMarkers = [];
  var isSOSvisible = true;

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(20.5937, 78.9629),
    zoom: 5,
  );

//  static final CameraPosition _kLake = CameraPosition(
//      bearing: 192.8334901395799,
//      target: LatLng(37.43296265331129, -122.08832357078792),
//      tilt: 59.440717697143555,
//      zoom: 19.151926040649414);

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
              width: MediaQuery.of(context).size.width * .70,
              height: 65,
              margin: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height,
                  left: MediaQuery.of(context).size.width - 350),
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
            SOSbuttun
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
    Position position = await Geolocator()
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

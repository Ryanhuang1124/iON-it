import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class FindMyCarDetail extends StatefulWidget {
  final List<String> destination;
  const FindMyCarDetail({Key key, @required this.destination})
      : super(key: key);

  @override
  _FindMyCarDetailState createState() => _FindMyCarDetailState();
}

class _FindMyCarDetailState extends State<FindMyCarDetail> {
  List<LatLng> polylineCoordinates = [];
  Map<PolylineId, Polyline> polylines = {};
  Map<MarkerId, Marker> markers = {};
  Future<Position> myLocation;
  BitmapDescriptor customMarker;

  GoogleMapController _mapController;

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.

    return await Geolocator.getCurrentPosition();

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
  }

  Future<bool> makeRoute(Position myLocation) async {
    PolylinePoints polylinePoints = PolylinePoints();

    double desLat = double.parse(widget.destination[0]);
    double desLng = double.parse(widget.destination[1]);
    //make polyline
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      "AIzaSyBUEBuJkwv-gFuEgvguWQC0c5It9SqTVLE", // Google Maps API Key
      PointLatLng(myLocation.latitude, myLocation.longitude),
      PointLatLng(desLat, desLng),
      travelMode: TravelMode.walking,
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }

    PolylineId pId = PolylineId('poly');
    MarkerId mStartId = MarkerId('start');
    MarkerId mDestinationId = MarkerId('Destination');

    //declare polyline
    Polyline polyline = Polyline(
      polylineId: pId,
      color: Colors.red,
      points: polylineCoordinates,
    );
    //declare marker
    Marker markerStart = Marker(
        markerId: mStartId,
        icon: customMarker,
        position: LatLng(myLocation.latitude, myLocation.longitude));
    Marker markerDestination = Marker(
        markerId: mDestinationId,
        icon: customMarker,
        position: LatLng(desLat, desLng));

    setState(() {
      polylines[pId] = polyline;
      markers[mStartId] = markerStart;
      markers[mDestinationId] = markerDestination;
    });

    return true;
  }

  LatLngBounds getBounds(List<Marker> markers) {
    var lngs = markers.map<double>((m) => m.position.longitude).toList();
    var lats = markers.map<double>((m) => m.position.latitude).toList();

    double topMost = lngs.reduce(max);
    double leftMost = lats.reduce(min);
    double rightMost = lats.reduce(max);
    double bottomMost = lngs.reduce(min);

    LatLngBounds bounds = LatLngBounds(
      northeast: LatLng(rightMost, topMost),
      southwest: LatLng(leftMost, bottomMost),
    );

    return bounds;
  }

  Future<bool> moveToPointCenter() async {
    //make all point marker to get center
    List<Marker> allPointsToMoveCamera = [];
    allPointsToMoveCamera.add(markers.values.first);
    for (var item in polylineCoordinates) {
      allPointsToMoveCamera.add(Marker(
        markerId: MarkerId('pathThrough'),
        position: item,
      ));
    }
    allPointsToMoveCamera.add(markers.values.last);

    LatLngBounds bounds = getBounds(allPointsToMoveCamera);

    CameraUpdate centerPoint = CameraUpdate.newLatLngBounds(
        bounds, MediaQuery.of(context).size.width * 0.1);
    await _mapController.animateCamera(centerPoint);
    return true;
  }

  Future<void> waitForGoogleMap(
      GoogleMapController c, LatLng initialMapCenter) {
    return c.getVisibleRegion().then((value) {
      if (value.southwest.latitude != initialMapCenter.latitude) {
        return Future.value();
      }

      return Future.delayed(Duration(milliseconds: 100))
          .then((_) => waitForGoogleMap(c, initialMapCenter));
    });
  }

  @override
  void initState() {
    super.initState();
    myLocation = _determinePosition();
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(
              size: Platform.isIOS ? Size(6, 6) : Size(12, 12),
            ),
            'assets/images/marker.png')
        .then((d) {
      customMarker = d;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Position>(
        future: myLocation,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(
                title: Text('Find my car'),
              ),
              body: GoogleMap(
                zoomControlsEnabled: false,
                myLocationEnabled: true,
                polylines: Set<Polyline>.of(polylines.values),
                markers: Set<Marker>.of(markers.values),
                initialCameraPosition: CameraPosition(
                  zoom: 16.5,
                  target:
                      LatLng(snapshot.data.latitude, snapshot.data.longitude),
                ),
                onMapCreated: (controller) async {
                  _mapController = controller;
                  await waitForGoogleMap(controller,
                      LatLng(snapshot.data.latitude, snapshot.data.longitude));
                  bool result =
                      await makeRoute(snapshot.data).whenComplete(() async {
                    await moveToPointCenter();
                  });
                },
              ),
            );
          } else {
            return Scaffold(
              appBar: AppBar(
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                  )
                ],
                title: Center(
                    child: Text(
                  'Find my car',
                  style: TextStyle(fontSize: 26, fontFamily: 'Arial'),
                )),
              ),
              body: Container(
                  child: Center(
                      child: CupertinoActivityIndicator(
                          radius: 20, animating: true))),
            );
          }
        });
  }
}

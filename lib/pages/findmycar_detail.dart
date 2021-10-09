import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:location/location.dart';

class FindMyCarDetail extends StatefulWidget {
  final List<String> destination;
  final String vehicleName;
  const FindMyCarDetail(
      {Key key, @required this.destination, @required this.vehicleName})
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
  Position position;

  GoogleMapController _mapController;



  Future<bool> doTheMapThing(Position position) async {
    await waitForGoogleMap(
        _mapController, LatLng(position.latitude, position.longitude));
    bool result = await makeRoute(position).whenComplete(() {});
    return result;
  }

  Future<bool> _checkLocationServiceEnable() async {
    var location = new Location();
    bool _serviceEnabled = false;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
    }
    return _serviceEnabled;
  }

  Future<Position> _determinePosition() async {
    print('into determine position');
    await Future.delayed(const Duration(seconds: 1), () {});
    bool serviceEnabled = false;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await _checkLocationServiceEnable();
    if (!serviceEnabled) {
      print('no service ');
      return null;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      print('Location permissions are denied');
      return null;
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      print(
          'Location permissions are permanently denied, we cannot request permissions.');
      return null;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.

    var position = await Geolocator.getCurrentPosition();

    return position;

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
        infoWindow: InfoWindow(title: widget.vehicleName),
        onTap: (){
          _mapController.showMarkerInfoWindow(MarkerId('Destination'));
        },
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
          if (snapshot.connectionState == ConnectionState.done) {


            if (snapshot.hasData) {

              return Scaffold(
                appBar: AppBar(
                  title: Text('Find my car',style: TextStyle( fontFamily: 'Arial'),),
                ),
                body: GoogleMap(
                  mapToolbarEnabled: false,
                  zoomControlsEnabled: false,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  polylines: Set<Polyline>.of(polylines.values),
                  markers: Set<Marker>.of(markers.values),
                  initialCameraPosition: CameraPosition(
                    zoom: 16.5,
                    target:
                        LatLng(snapshot.data.latitude, snapshot.data.longitude),
                  ),
                  onMapCreated: (controller) async {
                    _mapController = controller;
                    await doTheMapThing(snapshot.data).then((isMapDone)async {
                      if(isMapDone){
                        await moveToPointCenter().then((value)async {
                          await Future.delayed(const Duration(seconds: 1), (){
                            controller.showMarkerInfoWindow(MarkerId('Destination'));
                          });
                        });
                      }
                    });



                  },
                ),
              );
            } else {

              return Scaffold(
                appBar: AppBar(
                title: Text('Find my car',style: TextStyle( fontFamily: 'Arial'),),
          ),
                body: Container(
                    child: Center(
                        child: Text(
                  'Please Enable Location Service',
                  style: TextStyle(fontFamily: 'Arial', fontSize: 22),
                ))),
              );
            }
          } else {
            return Scaffold(
              appBar:AppBar(
              title: Text('Find my car',style: TextStyle( fontFamily: 'Arial'),),
          ),
              body: Container(
                  child: Center(
                      child: CupertinoActivityIndicator(
                radius: 20,
                animating: true,
              ))),
            );
          }
        });
  }
}

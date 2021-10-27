import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:app_settings/app_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:ion_it/main.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

class Position {
  var latitude;
  var longitude;
  Position(var latitude, var longitude) {
    this.latitude = latitude;
    this.longitude = longitude;
  }
}

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
  Position position;
  GoogleMapController _mapController;
  Map<String, String> hintText = {
    'en':
        'Please allow the location services and permission.\nIf your location permission is \n" Denied Forever ", go to settings and change it.',
    'zh': '請打開定位服務並允許位置權限。\n如果裝置位置權限為\n「永不」，請到設定中變更為其他選擇，並重新進入此頁。'
  };

  Map<String, List<String>> btnText = {
    'en': ['settings', 'allow'],
    'zh': ['設定', '允許'],
  };

  //turn asset image to Uint8List for marker Icon
  Future<BitmapDescriptor> getMarkerIconFromAsset(String path) async {
    var result;
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: 90);
    ui.FrameInfo fi = await codec.getNextFrame();
    result = (await fi.image.toByteData(format: ui.ImageByteFormat.png))
        .buffer
        .asUint8List();
    BitmapDescriptor.fromBytes(result);
    return BitmapDescriptor.fromBytes(result);
  }

  Future<bool> doTheMapThing(Position position) async {
    await waitForGoogleMap(
        _mapController, LatLng(position.latitude, position.longitude));
    bool result = await makeRoute(position).whenComplete(() {});
    return result;
  }

  Future<Position> _determinePosition() async {
    await Future.delayed(const Duration(seconds: 1), () {});
    Location location = new Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return null;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }

    _locationData = await location.getLocation();
    Position position =
        new Position(_locationData.latitude, _locationData.longitude);
    return position;
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
    //declare markers
    Marker markerStart = Marker(
        markerId: mStartId,
        icon: await getMarkerIconFromAsset('assets/images/marker.png'),
        position: LatLng(myLocation.latitude, myLocation.longitude));

    Marker markerDestination = Marker(
        infoWindow: InfoWindow(title: widget.vehicleName),
        onTap: () {
          _mapController.showMarkerInfoWindow(MarkerId('Destination'));
        },
        markerId: mDestinationId,
        icon: await getMarkerIconFromAsset('assets/images/marker.png'),
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
                  title: Text(
                    'Find my car',
                    style: TextStyle(fontFamily: 'Arial'),
                  ),
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
                    await doTheMapThing(snapshot.data).then((isMapDone) async {
                      if (isMapDone) {
                        await moveToPointCenter().then((value) async {
                          await Future.delayed(const Duration(seconds: 1), () {
                            controller
                                .showMarkerInfoWindow(MarkerId('Destination'));
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
                  title: Text(
                    'Find my car',
                    style: TextStyle(fontFamily: 'Arial'),
                  ),
                ),
                body: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 1, child: SizedBox()),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                            child: Text(
                          Provider.of<Data>(context, listen: false)
                                      .localeName ==
                                  'zh'
                              ? hintText['zh']
                              : hintText['en'],
                          style: TextStyle(fontFamily: 'Arial', fontSize: 22),
                        )),
                      ),
                      ElevatedButton(
                          onPressed: AppSettings.openLocationSettings,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              Provider.of<Data>(context, listen: false)
                                          .localeName ==
                                      'zh'
                                  ? btnText['zh'][0]
                                  : btnText['en'][0],
                              style:
                                  TextStyle(fontFamily: 'Arial', fontSize: 22),
                            ),
                          )),
                      Expanded(flex: 5, child: SizedBox()),
                    ],
                  ),
                ),
              );
            }
          } else {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  'Find my car',
                  style: TextStyle(fontFamily: 'Arial'),
                ),
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

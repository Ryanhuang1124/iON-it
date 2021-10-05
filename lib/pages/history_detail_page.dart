import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:ion_it/main.dart';
import 'package:provider/provider.dart';

class HistoryRouteData {
  String status;
  String stDate;
  int duration;
  String distance = '';
  String maxSpeed;
  List<dynamic> records = [];
  String stopAddress;
}

class HistoryDetail extends StatefulWidget {
  final String jsonData;

  const HistoryDetail({Key key, @required this.jsonData}) : super(key: key);

  @override
  _HistoryDetailState createState() => _HistoryDetailState();
}

class _HistoryDetailState extends State<HistoryDetail> {
  GoogleMapController _mapController;
  List<LatLng> routeCoords = [];
  Set<Marker> marks = {};
  Set<Polyline> polyline = {};
  List<Widget> containerList = [];

  Future<List<HistoryRouteData>> historyRouteData;
  BitmapDescriptor customMarker;

  CameraUpdate centerPoint;

  Future<String> getAddress(String lat, String lng) async {
    String uri = "https://web.onlinetraq.com/module/APIv1/006-1.php";
    var data = json.decode(widget.jsonData);
    var jsonData = json.encode({
      "server": data['server'],
      "user": data['user'],
      "pass": data['pass'],
      "lat": lat,
      "lng": lng,
      "lang": "en"
    });
    FormData formData = FormData.fromMap({'data': jsonData});
    var response = await Dio().post(uri, data: formData);
    Map<String, dynamic> finalData = json.decode(response.data);

    if (finalData['status'] == 'S' && response.statusCode == 200) {
      return finalData['data'];
    }
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

  String durationToString(int seconds) {
    if (seconds != null) {
      var d = Duration(seconds: seconds).toString().split(".");
      return d[0];
    } else {
      return "0";
    }
  }

  Future<List<HistoryRouteData>> getVehicleHistory() async {
    List<HistoryRouteData> routeList = [];

    String server = Provider.of<Data>(context, listen: false).server;
    String user = Provider.of<Data>(context, listen: false).user;
    String pass = Provider.of<Data>(context, listen: false).pass;
    String id = Provider.of<Data>(context, listen: false).historyId;
    DateTime date = Provider.of<Data>(context, listen: false).historyDate;
    DateTime stTime = Provider.of<Data>(context, listen: false).historyStTime;
    DateTime edTime = Provider.of<Data>(context, listen: false).historyEdTime;
    String uri = "https://web.onlinetraq.com/module/APIv1/003-3.php";

    String sDate = DateFormat('yyyy-MM-dd').format(date);
    String sTime = DateFormat('HH:mm:ss').format(stTime);
    String eTime = DateFormat('HH:mm:ss').format(edTime);

    var jsonData = json.encode({
      "server": server,
      "user": user,
      "pass": pass,
      "deviceID": int.parse(id),
      "sDate": sDate,
      "stTime": sTime,
      "edTime": eTime
    });
    FormData formData = FormData.fromMap({'data': jsonData});

    var response = await Dio().post(uri, data: formData);
    Map<String, dynamic> data = json.decode(response.data);

    for (var item in data['data']) {
      HistoryRouteData obj = new HistoryRouteData();
      obj.status = item['status'];
      obj.stDate = item['st'];
      obj.duration = item['total'];
      obj.distance = item['dist'].toString();
      obj.maxSpeed = item['maxSpeed'];
      obj.records = item['records'];
      if (obj.status == 'S' || obj.status == 'I') {
        if (item['records'][0]['lat'] != null &&
            item['records'][0]['lng'] != null) {
          String address = await getAddress(
              item['records'][0]['lat'], item['records'][0]['lng']);
          obj.stopAddress = address;
        }
      }
      routeList.add(obj);
    }
    return routeList;
  }

  Future<bool> moveToPointCenter() async {
    LatLngBounds bounds = getBounds(marks.toList());
    CameraUpdate centerPoint = CameraUpdate.newLatLngBounds(bounds, 50);
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
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(
              size: Platform.isIOS ? Size(6, 6) : Size(12, 12),
            ),
            'assets/images/marker.png')
        .then((d) {
      customMarker = d;
    });
    historyRouteData = getVehicleHistory();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HistoryRouteData>>(
        future: historyRouteData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData && snapshot.data.isNotEmpty) {
              List<LatLng> polylinePoints = [];
              List<LatLng> markerPoints = [];
              List<Widget> bottomList = [];
              for (var obj in snapshot.data) {
                if (obj.records != null) {
                  obj.records.forEach((element) {
                    if ((!["", null, false, 0].contains(element["lat"])) &&
                        (!["", null, false, 0].contains(element["lng"]))) {
                      polylinePoints.add(
                        LatLng(
                          double.parse(element['lat']),
                          double.parse(element['lng']),
                        ),
                      );
                      if (obj.status == 'S' || obj.status == 'I') {
                        markerPoints.add(
                          LatLng(
                            double.parse(element['lat']),
                            double.parse(element['lng']),
                          ),
                        );
                      }
                    }
                  });
                }
              }
              if (polylinePoints.isEmpty) {
                polylinePoints
                    .add(LatLng(24.96538069686663, 121.43875091494725));
              }
              if (markerPoints.isEmpty) {
                markerPoints.add(LatLng(24.96538069686663, 121.43875091494725));
              }
              polyline.add(Polyline(
                  polylineId: PolylineId(snapshot.data[0].stDate.toString()),
                  visible: true,
                  points: polylinePoints,
                  color: Color.fromRGBO(0, 0, 155, 1)));

              for (var position in markerPoints) {
                marks.add(Marker(
                    markerId: MarkerId(snapshot.data[0].stDate.toString()),
                    position: position,
                    icon: customMarker));
              }

              for (var obj in snapshot.data) {
                if (obj.status == 'S') {
                  bottomList.add(
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(width: 1, color: Colors.black26),
                        ),
                      ),
                      height: MediaQuery.of(context).size.height * 0.2,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8, right: 8),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/svg/stop.svg',
                              width: MediaQuery.of(context).size.height * 0.1,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    top: 12, bottom: 12, left: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Date: ${obj.stDate}',
                                      style: TextStyle(
                                          fontSize: 20, fontFamily: 'Arial'),
                                      softWrap: true,
                                      maxLines: 2,
                                    ),
                                    Text(
                                      'Duration: ${durationToString(obj.duration)}',
                                      style: TextStyle(
                                          fontSize: 20, fontFamily: 'Arial'),
                                      softWrap: true,
                                      maxLines: 2,
                                    ),
                                    Expanded(
                                      child: Text(
                                        obj.stopAddress != null
                                            ? obj.stopAddress
                                            : '',
                                        style: TextStyle(
                                            fontSize: 20, fontFamily: 'Arial'),
                                        softWrap: true,
                                        maxLines: 3,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                if (obj.status == 'D') {
                  bottomList.add(
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(width: 1, color: Colors.black26),
                        ),
                      ),
                      height: MediaQuery.of(context).size.height * 0.2,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8, right: 8),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/svg/driving.svg',
                              width: MediaQuery.of(context).size.height * 0.1,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 12, bottom: 12, left: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date: ${obj.stDate}',
                                    style: TextStyle(
                                        fontSize: 20, fontFamily: 'Arial'),
                                  ),
                                  Text(
                                    'Duration: ${durationToString(obj.duration)}',
                                    style: TextStyle(
                                        fontSize: 20, fontFamily: 'Arial'),
                                  ),
                                  Text(
                                    'Distance: ${(double.parse(obj.distance) / 1000).toStringAsFixed(2)}  km ',
                                    style: TextStyle(
                                        fontSize: 20, fontFamily: 'Arial'),
                                  ),
                                  Text(
                                    'max. speed:${(int.parse(obj.maxSpeed) / 1000).toStringAsFixed(2)}  km/h',
                                    style: TextStyle(
                                        fontSize: 20, fontFamily: 'Arial'),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                if (obj.status == 'I') {
                  bottomList.add(
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(width: 1, color: Colors.black26),
                        ),
                      ),
                      height: MediaQuery.of(context).size.height * 0.2,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8, right: 8),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/svg/idle.svg',
                              width: MediaQuery.of(context).size.height * 0.1,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    top: 12, bottom: 12, left: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Date: ${obj.stDate}',
                                      style: TextStyle(
                                          fontSize: 20, fontFamily: 'Arial'),
                                      softWrap: true,
                                      maxLines: 2,
                                    ),
                                    Text(
                                      'Duration: ${durationToString(obj.duration)}',
                                      style: TextStyle(
                                          fontSize: 20, fontFamily: 'Arial'),
                                      softWrap: true,
                                      maxLines: 2,
                                    ),
                                    Expanded(
                                      child: Text(
                                        obj.stopAddress != null
                                            ? obj.stopAddress
                                            : '',
                                        style: TextStyle(
                                            fontSize: 20, fontFamily: 'Arial'),
                                        softWrap: true,
                                        maxLines: 3,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              }

              return Scaffold(
                appBar: AppBar(
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                    )
                  ],
                  title: Center(
                      child: Text(
                    'Breadcrumb Trail',
                    style: TextStyle(fontSize: 26, fontFamily: 'Arial'),
                  )),
                ),
                body: Column(
                  children: [
                    Container(
                      child: GoogleMap(
                        myLocationButtonEnabled: false,
                        markers: marks,
                        polylines: polyline,
                        compassEnabled: true,
                        initialCameraPosition: CameraPosition(
                          target: polylinePoints[0],
                          zoom: 16.5,
                        ),
                        zoomControlsEnabled: false,
                        onMapCreated: (controller) async {
                          _mapController = controller;
                          var update = () async {
                            var region = await controller.getVisibleRegion();
                            // check visible region
                            if (region.southwest.latitude == 0.0) {
                              return false;
                            }
                            await moveToPointCenter();
                            return true;
                          };
                          while (await update() == false) {
                            update();
                          }
                        },
                      ),
                      height: MediaQuery.of(context).size.height * 0.5,
                      width: MediaQuery.of(context).size.width,
                    ),
                    Expanded(
                      child: Container(
                        child: ListView(
                          children: bottomList,
                        ),
                      ),
                    ),
                  ],
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
                    'Breadcrumb Trail',
                    style: TextStyle(fontSize: 26, fontFamily: 'Arial'),
                  )),
                ),
                body: Container(
                    child: Center(
                  child: Text(
                    'No data',
                    style: TextStyle(fontSize: 30),
                  ),
                )),
              );
            }
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
                  'Breadcrumb Trail',
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

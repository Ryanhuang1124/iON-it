import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:ion_it/main.dart';
import 'package:ion_it/pages/edit_location_passing.dart';
import 'package:ion_it/pages/passing_by_record_detail.dart';
import 'package:ion_it/pages/select_radius_passing.dart';
import 'package:provider/provider.dart';

class PassingByRecord extends StatefulWidget {
  final String jsonData;
  final LatLng myLocation;

  const PassingByRecord(
      {Key key, @required this.jsonData, @required this.myLocation})
      : super(key: key);
  @override
  _PassingByRecordState createState() => _PassingByRecordState();
}

class _PassingByRecordState extends State<PassingByRecord> {
  BitmapDescriptor customMarker;
  GoogleMapController _mapController;
  Map<String, Marker> point = {};
  Map<String, Circle> round = {};

  void locationImage() {
    var position = Provider.of<Data>(context, listen: false).passingPosition;

    Marker marker = Marker(
      position: position == null ? LatLng(25.046273, 121.517498) : position,
      visible: position != null,
      icon: customMarker,
      markerId: MarkerId('666'),
    );
    Circle circle = Circle(
      visible: position != null,
      radius: Provider.of<Data>(context, listen: false).passingRadius * 1000,
      circleId: CircleId('666'),
      center: position == null ? LatLng(25.046273, 121.517498) : position,
    );

    setState(() {
      point['passingLocation'] = marker;
      round['passingLocation'] = circle;
    });
    double zoom;
    int radius =
        (Provider.of<Data>(context, listen: false).passingRadius * 10).round();

    switch (radius) {
      case 0:
        zoom = 14;
        break;
      case 5:
        zoom = 14.8;
        break;
      case 10:
        zoom = 13.8;
        break;
      case 15:
        zoom = 13.2;
        break;
      case 20:
        zoom = 12.8;
        break;
    }

    if (position != null) {
      _mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: zoom)));
    }
  }

  @override
  void initState() {
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(
              size: Platform.isIOS ? Size(6, 6) : Size(12, 12),
            ),
            'assets/images/marker.png')
        .then((d) {
      customMarker = d;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Provider.of<Data>(context, listen: false).changeFocus(false);
        Provider.of<Data>(context, listen: false).changeFocusVehicles('');
        Provider.of<Data>(context, listen: false).passingPosition = null;
        Provider.of<Data>(context, listen: false).passingRadius = 0;
        return true;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 14),
            )
          ],
          title: Center(
              child: Text(
            'Passing-By Record',
            style: TextStyle(fontSize: 26, fontFamily: 'Arial'),
          )),
        ),
        body: Container(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12),
                child: GestureDetector(
                  onTap: () {
                    DatePicker.showDatePicker(context, onConfirm: (date) {
                      Provider.of<Data>(context, listen: false)
                          .changePassingDate(date);
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        border: Border(
                            bottom:
                                BorderSide(width: 1, color: Colors.black26))),
                    height: MediaQuery.of(context).size.height / 14,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Date',
                          style: TextStyle(fontSize: 20, fontFamily: 'Arial'),
                        ),
                        Container(
                            child: Text(
                          DateFormat("yyyy-MM-dd")
                              .format(Provider.of<Data>(context).passingDate),
                          style: TextStyle(fontSize: 20, fontFamily: 'Arial'),
                        )),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12),
                child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SelectRadiusPassing(
                                  jsonData: widget.jsonData))).then((value) {
                        locationImage();
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          border: Border(
                              bottom:
                                  BorderSide(width: 1, color: Colors.black26))),
                      height: MediaQuery.of(context).size.height / 14,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Radius',
                            style: TextStyle(fontSize: 20, fontFamily: 'Arial'),
                          ),
                          Text(
                            "${Provider.of<Data>(context).passingRadius.toString()} km",
                            style: TextStyle(fontSize: 20, fontFamily: 'Arial'),
                          ),
                        ],
                      ),
                    )),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12),
                child: Container(
                  height: MediaQuery.of(context).size.height / 14,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Location',
                        style: TextStyle(fontSize: 20, fontFamily: 'Arial'),
                      ),
                      IconButton(
                          icon: Icon(
                            Icons.navigate_next,
                            size: 40,
                            color: Colors.black45,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => EditLocationPassing(
                                      jsonData: widget.jsonData)),
                            ).then((value) {
                              locationImage();
                            });
                          }),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                child: Container(
                  height: MediaQuery.of(context).size.height / 3,
                  child: GoogleMap(
                    myLocationButtonEnabled: false,
                    compassEnabled: false,
                    zoomControlsEnabled: false,
                    myLocationEnabled: true,
                    onMapCreated: (mapController) {
                      _mapController = mapController;
                    },
                    initialCameraPosition: CameraPosition(
                      target: Provider.of<Data>(context, listen: false)
                                  .passingPosition !=
                              null
                          ? Provider.of<Data>(context, listen: false)
                              .passingPosition
                          : widget.myLocation != null
                              ? widget.myLocation
                              : LatLng(24.96538069686663, 121.43875091494725),
                      zoom: 14,
                    ),
                    markers: Set<Marker>.of(point.values),
                    circles: Set<Circle>.of(round.values),
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height / 10,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12),
                child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PassingByRecordDetail(
                                  jsonData: widget.jsonData)));
                    },
                    child: Container(
                      child: Center(
                          child: Text(
                        'Inquire',
                        style: TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontFamily: 'Arial'),
                      )),
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height / 14,
                      decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(30)),
                    )),
              )
            ],
          ),
        ),
      ),
    );
  }
}

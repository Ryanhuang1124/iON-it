import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ion_it/pages/smartfence_page.dart';
import 'package:provider/provider.dart';
import 'package:ion_it/main.dart';

class EditLocation extends StatefulWidget {
  final LatLng position;
  final String jsonData;
  final BitmapDescriptor markerIcon;

  const EditLocation(
      {Key key,
      @required this.position,
      @required this.jsonData,
      @required this.markerIcon})
      : super(key: key);
  @override
  _EditLocationState createState() => _EditLocationState();
}

class _EditLocationState extends State<EditLocation> {
  GoogleMapController _mapController;
  Map<String, Marker> point = {};
  String address;

  Future<String> getAddress(LatLng point) async {
    String uri = "https://web.onlinetraq.com/module/APIv1/006-1.php";
    var data = json.decode(widget.jsonData);
    var jsonData = json.encode({
      "server": data['server'],
      "user": data['user'],
      "pass": data['pass'],
      "lat": point.latitude,
      "lng": point.longitude,
      "lang": "zh-TW"
    });
    FormData formData = FormData.fromMap({'data': jsonData});
    var response = await Dio().post(uri, data: formData);
    Map<String, dynamic> finalData = json.decode(response.data);

    if (finalData['status'] == 'S' && response.statusCode == 200) {
      return finalData['data'];
    } else {
      return 'No Data';
    }
  }

  handleTap(LatLng position) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
            onWillPop: () => Future.value(false),
            child: CupertinoActivityIndicator(
              radius: 20,
              animating: true,
            )));

    address = await getAddress(position).whenComplete(() {
      Navigator.pop(context);
    });

    Marker marker = Marker(
      icon: widget.markerIcon,
      markerId: MarkerId(position.toString()),
      position: position,
    );
    setState(() {
      point['smartFenceLocation'] = marker;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
            child: Text(
          'Edit Location',
          style: TextStyle(fontSize: 26, fontFamily: 'Arial'),
        )),
      ),
      bottomSheet: FutureBuilder<String>(
          future: getAddress(widget.position),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Container(
                padding: EdgeInsets.only(left: 16, right: 16),
                decoration: BoxDecoration(
                    color: Color.fromRGBO(247, 247, 247, 1),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20))),
                height: MediaQuery.of(context).size.height / 4,
                child: Column(
                  children: [
                    Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            child: Text(
                              address == null ? snapshot.data : address,
                              style: TextStyle(
                                fontSize: 22,
                                fontFamily: 'Arial',
                              ),
                              softWrap: true,
                              maxLines: 3,
                            ),
                          ),
                        )),
                    Expanded(
                        flex: 1,
                        child: Container(
                          decoration: BoxDecoration(
                              border: Border(
                                  top: BorderSide(
                                      color: Colors.black26, width: 1))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (point != null) {
                                    String name = Provider.of<Data>(context,
                                            listen: false)
                                        .smartFenceVehicle;
                                    SmartFenceData obj = Provider.of<Data>(
                                            context,
                                            listen: false)
                                        .smartData[name];
                                    obj.smartFenceLocation =
                                        point['smartFenceLocation'].position;
                                    Provider.of<Data>(context, listen: false)
                                        .changeSmartFenceData(obj);
                                    // Provider.of<Data>(context,listen: false).changeSmartFenceMarker(point['smartFenceLocation'].position);
                                  }

                                  Navigator.pop(context);
                                },
                                child: Container(
                                  child: SvgPicture.asset(
                                    'assets/svg/confirm.svg',
                                    height:
                                        MediaQuery.of(context).size.height / 15,
                                  ),
                                ),
                              )
                            ],
                          ),
                        )),
                  ],
                ),
              );
            } else {
              return Center(
                  child: CupertinoActivityIndicator(
                radius: 20,
                animating: true,
              ));
            }
          }),
      body: GoogleMap(
        myLocationEnabled: true,
        onMapCreated: (mapController) {
          Marker marker = Marker(
            icon: widget.markerIcon,
            markerId: MarkerId(widget.position.toString()),
            position: Provider.of<Data>(context, listen: false)
                        .smartFenceMarker ==
                    null
                ? widget.position
                : Provider.of<Data>(context, listen: false).smartFenceMarker,
          );
          setState(() {
            point['smartFenceLocation'] = marker;
          });

          _mapController = mapController;
        },
        initialCameraPosition: CameraPosition(
          target: Provider.of<Data>(context).smartFenceMarker == null
              ? LatLng(
                  widget.position.latitude - 0.001, widget.position.longitude)
              : LatLng(
                  Provider.of<Data>(context).smartFenceMarker.latitude - 0.001,
                  Provider.of<Data>(context).smartFenceMarker.longitude),
          zoom: 16,
        ),
        markers: Set<Marker>.of(point.values),
        onTap: handleTap,
      ),
    );
  }
}

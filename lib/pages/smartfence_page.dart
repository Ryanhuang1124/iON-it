import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:ion_it/main.dart';
import 'package:ion_it/pages/edit_location.dart';
import 'package:ion_it/pages/home_page.dart';
import 'package:ion_it/pages/in_out_door.dart';
import 'package:ion_it/pages/select_radius.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sms/flutter_sms.dart';

class SMSData {
  String name;
  String phone;
  String imei;
}

class SmartFenceData {
  LatLng smartFenceLocation;
  double smartFenceRadius = 150;
  String smartFenceVehicle;
  bool smartFenceActivate = false;
}

class SmartFence extends StatefulWidget {
  final String jsonData;
  const SmartFence({Key key, @required this.jsonData}) : super(key: key);
  @override
  _SmartFenceState createState() => _SmartFenceState();
}

class _SmartFenceState extends State<SmartFence> {
  BitmapDescriptor customMarker;
  GoogleMapController _mapController;
  List<SMSData> smsDataList = [];
  String generateRandomString(int len) {
    var r = Random();
    const _chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    return List.generate(len, (index) => _chars[r.nextInt(_chars.length)])
        .join();
  }

  Future<Map<String, dynamic>> uploadSmartFenceData(
      int id, String type, String immobilizer, String name) async {
    String server = Provider.of<Data>(context, listen: false).server;
    String user = Provider.of<Data>(context, listen: false).user;
    String pass = Provider.of<Data>(context, listen: false).pass;
    LatLng position = Provider.of<Data>(context, listen: false)
        .smartData[name]
        .smartFenceLocation;
    double range = Provider.of<Data>(context, listen: false)
        .smartData[name]
        .smartFenceRadius;
    String parking =
        Provider.of<Data>(context, listen: false).smartFenceIndoor ? "Y" : "N";

    DateTime now = new DateTime.now();
    String date = new DateTime(
            now.year, now.month, now.day, now.hour, now.minute, now.second)
        .toString()
        .split('.')[0];

    if (position != null && range != 0) {
      String uri = "https://web.onlinetraq.com/module/APIv1/004-3.php";
      var jsonData = json.encode({
        "server": server,
        "user": user,
        "pass": pass,
        "deviceID": id,
        "type": type,
        "sDate": date.toString(),
        "setLat": position.latitude,
        "setLng": position.longitude,
        "setRange": range,
        "setUnit": "M",
        "indoorParking": parking,
        "immobilizer": immobilizer,
        "bluetooth": "N"
      });
      FormData formData = FormData.fromMap({'data': jsonData});

      var response = await Dio().post(uri, data: formData);
      Map<String, dynamic> data = json.decode(response.data);

      return data;
    }
  }

  Future<Map<dynamic, List>> getVehicles() async {
    Map<dynamic, List> allVehiclesData = <dynamic, List>{};
    List<String> idList = [];

    String uri = "https://web.onlinetraq.com/module/APIv1/003-1.php";
    FormData formData = FormData.fromMap({'data': widget.jsonData});
    var response = await Dio().post(uri, data: formData);
    Map<String, dynamic> data = json.decode(response.data);

    for (var item in data['data']) {
      SMSData obj = new SMSData();
      List value = [];
      value.add(item['name']);
      allVehiclesData[item['id']] = value;
      obj.name = item['name'];
      obj.imei = item['imei'];
      obj.phone = item['phone'];
      smsDataList.add(obj);
    }
    allVehiclesData.forEach((key, value) {
      idList.add(key);
    });
    Map<String, dynamic> rebuildJson = json.decode(widget.jsonData); //decode
    rebuildJson['device'] = idList; //add {device:idList}
    var jsonData2 = json.encode(rebuildJson); //encode
    FormData formData2 = FormData.fromMap({'data': jsonData2}); //form
    String uri2 = "https://web.onlinetraq.com/module/APIv1/003-2.php";
    var response2 = await Dio().post(uri2, data: formData2); //post
    Map<String, dynamic> data2 = json.decode(response2.data); //decode

    //build final Map<id,list>
    data2['data'].forEach((key, value) {
      allVehiclesData[key].add(value['locat']);
      allVehiclesData[key].add(value['status']);
      allVehiclesData[key].add(value['speed']);
      allVehiclesData[key].add(value['date']);
      allVehiclesData[key].add(value['driStat']);
      allVehiclesData[key].add(value['at1']);
      allVehiclesData[key].add(value['at2']);
      allVehiclesData[key].add(value['at3']);
      allVehiclesData[key].add(value['at4']);
      allVehiclesData[key].add(value['at5']);
      allVehiclesData[key].add(value['at6']);
    });

    print(allVehiclesData);

    return allVehiclesData;
  }

  String encodeSMS() {
    String lastTwo = DateFormat('dd').format(DateTime.now());
    String name = Provider.of<Data>(context, listen: false).smartFenceVehicle;
    String imei;
    String phone;
    String code;
    for (var item in smsDataList) {
      if (item.name == name) {
        imei = item.imei;
        phone = item.phone;
      }
    }
    if (imei != null) {
      code = imei.substring(0, imei.length - 1);
      code = code.substring(code.length - 6);
      code = code + lastTwo;
      List<String> splitString = [];
      for (int i = 0; i < 8; i = i + 2) {
        splitString.add(code.substring(code.length - 2));
        code = code.substring(0, code.length - 2);
      }
      splitString = splitString.reversed.toList();
      String hexString = '';
      for (var item in splitString) {
        item = int.parse(item).toRadixString(16);
        item = item.padLeft(2, '0');
        hexString = hexString + item;
      }

      List<String> mainCode = [];
      List<String> randomCode = [];
      hexString.runes.forEach((int rune) {
        var character = new String.fromCharCode(rune);
        mainCode.add(character);
      });
      String rand = generateRandomString(32);
      rand.runes.forEach((int rune) {
        var character = new String.fromCharCode(rune);
        randomCode.add(character);
      });
      for (int i = 0; i < 8; i++) {
        randomCode.insert(5 * i + 4, mainCode[i]);
      }
      String finalCode = '';
      for (var item in randomCode) {
        finalCode = finalCode + item;
      }
      return finalCode;
    }
  }

  void _sendSMS(String message, List<String> recipents) async {
    String _result = await sendSMS(message: message, recipients: recipents)
        .catchError((onError) {
      print(onError);
    });
    print(_result);
  }

  _textMe(int type, name) async {
    String name = Provider.of<Data>(context, listen: false).smartFenceVehicle;
    String phone;
    String apeN = encodeSMS();
    String lat;
    String lng;
    double range;
    var uri;
    for (var item in smsDataList) {
      if (item.name == name) {
        phone = item.phone;
      }
    }
    lat = (Provider.of<Data>(context, listen: false)
                .smartData[name]
                .smartFenceLocation
                .latitude *
            100)
        .toString();
    lng = (Provider.of<Data>(context, listen: false)
                .smartData[name]
                .smartFenceLocation
                .longitude *
            100)
        .toString();
    range = Provider.of<Data>(context, listen: false)
        .smartData[name]
        .smartFenceRadius;
    if (type == 0) {
      uri = '$apeN,park,$lat,N,$lng,E,$range,1*';
    }
    if (type == 1) {
      uri = '$apeN,park2,$lat,N,$lng,E,$range,1*';
    }
    if (type == 2) {
      uri = '$apeN,2;7,FF*';
    }
    if (type == 3) {
      uri = '$apeN,park2,0*';
    }
    String totalUri = 'sms:$phone?body=%23%23$uri';
    print(totalUri);

    String message = "##$uri";
    List<String> recipents = [phone];

    _sendSMS(message, recipents);
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
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<dynamic, List>>(
      future: getVehicles(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var id, name;
          name = Provider.of<Data>(context, listen: false).smartFenceVehicle;
          snapshot.data.forEach((key, value) {
            if (value[0] == name) {
              id = key;
            }
          });

          List<String> latlng = snapshot.data[id][1].split(',');
          var location =
              LatLng(double.parse(latlng[0]), double.parse(latlng[1]));

          if (Provider.of<Data>(context, listen: false).smartData[name] ==
              null) {
            SmartFenceData obj = new SmartFenceData();
            obj.smartFenceVehicle = name;
            obj.smartFenceLocation = location;
            Provider.of<Data>(context, listen: false)
                .smartData[obj.smartFenceVehicle] = obj;
          }
          Map<String, Marker> markers = {};
          Marker mark = Marker(
              icon: customMarker,
              markerId: MarkerId(id.toString()),
              position: location);
          markers[id] = mark;

          Map<String, Circle> circles = {};
          Circle circle = Circle(
            circleId: CircleId(id),
            radius: Provider.of<Data>(context, listen: false)
                .smartData[name]
                .smartFenceRadius,
            center: Provider.of<Data>(context, listen: false)
                .smartData[name]
                .smartFenceLocation,
          );
          circles[id] = circle;

          return WillPopScope(
            onWillPop: () async {
              Provider.of<Data>(context, listen: false).changeFocus(false);
              Provider.of<Data>(context, listen: false).changeFocusVehicles('');

              return true;
            },
            child: Scaffold(
              appBar: AppBar(
                title: Center(
                    child: Text(
                  'Smart Fence',
                  style: TextStyle(fontSize: 26, fontFamily: 'Arial'),
                )),
              ),
              bottomSheet: Container(
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
                        child: Container(
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: Colors.black26, width: 1))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  SelectRadius(name: name)))
                                      .then((value) {
                                    if (Provider.of<Data>(context,
                                                listen: false)
                                            .smartFenceMarker !=
                                        null) {
                                      _mapController.animateCamera(
                                          CameraUpdate.newCameraPosition(
                                              CameraPosition(
                                                  target: LatLng(
                                                      Provider.of<Data>(context,
                                                                  listen: false)
                                                              .smartFenceMarker
                                                              .latitude -
                                                          0.001,
                                                      Provider.of<Data>(context,
                                                              listen: false)
                                                          .smartFenceMarker
                                                          .longitude),
                                                  zoom: 16)));
                                    }
                                  });
                                },
                                child: Container(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/svg/editrange.svg',
                                        height: 40,
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Center(
                                          child: Text(
                                        'Edit range',
                                        style: TextStyle(color: Colors.grey),
                                      )),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width / 100,
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => EditLocation(
                                                position: location,
                                                jsonData: widget.jsonData,
                                              ))).then((value) {
                                    if (Provider.of<Data>(context,
                                                listen: false)
                                            .smartData[name]
                                            .smartFenceLocation !=
                                        null) {
                                      _mapController.animateCamera(CameraUpdate
                                          .newCameraPosition(CameraPosition(
                                              target: LatLng(
                                                  Provider.of<Data>(context,
                                                              listen: false)
                                                          .smartData[name]
                                                          .smartFenceLocation
                                                          .latitude -
                                                      0.001,
                                                  Provider.of<Data>(context,
                                                          listen: false)
                                                      .smartData[name]
                                                      .smartFenceLocation
                                                      .longitude),
                                              zoom: 16)));
                                    }
                                  });
                                },
                                child: Container(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/svg/editlocation.svg',
                                        height: 40,
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Center(
                                          child: Text(
                                        'Edit location',
                                        style: TextStyle(color: Colors.grey),
                                      )),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width / 100,
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => InOutDoor()));
                                },
                                child: Container(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/svg/in_out_door.svg',
                                        height: 40,
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Center(
                                          child: Text(
                                        'in/out door',
                                        style: TextStyle(color: Colors.grey),
                                      )),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                    Expanded(
                        flex: 1,
                        child: Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 5,
                                child: ElevatedButton(
                                    onPressed: () async {
                                      int idInt = int.parse(id);
                                      showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (context) => WillPopScope(
                                              onWillPop: () =>
                                                  Future.value(false),
                                              child: CupertinoActivityIndicator(
                                                radius: 20,
                                                animating: true,
                                              )));
                                      Map<String, dynamic> data =
                                          await uploadSmartFenceData(
                                                  idInt, "C", "N", name)
                                              .whenComplete(() => Navigator.of(
                                                      context,
                                                      rootNavigator: true)
                                                  .pop());

                                      if (data['status'] == 'Y') {
                                        SmartFenceData obj = Provider.of<Data>(
                                                context,
                                                listen: false)
                                            .smartData[name];
                                        obj.smartFenceActivate = false;
                                        Provider.of<Data>(context,
                                                listen: false)
                                            .changeSmartFenceData(obj);
                                      }

                                      _textMe(3, name);
                                      Navigator.of(context)
                                          .popUntil((route) => route.isFirst);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Deactivate',
                                        style: TextStyle(
                                          fontSize: 20,
                                        ),
                                      ),
                                    )),
                              ),
                              Expanded(flex: 1, child: SizedBox()),
                              Expanded(
                                flex: 5,
                                child: ElevatedButton(
                                    onPressed: () async {
                                      showDialog(
                                          context: context,
                                          builder: (BuildContext context) =>
                                              CupertinoAlertDialog(
                                                title: Text(
                                                    "Would you like to activate immobiliser?"),
                                                actions: <Widget>[
                                                  CupertinoDialogAction(
                                                    onPressed: () async {
                                                      int idInt = int.parse(id);

                                                      showDialog(
                                                          context: context,
                                                          barrierDismissible:
                                                              false,
                                                          builder: (context) =>
                                                              WillPopScope(
                                                                  onWillPop: () =>
                                                                      Future.value(
                                                                          false),
                                                                  child:
                                                                      CupertinoActivityIndicator(
                                                                    radius: 20,
                                                                    animating:
                                                                        true,
                                                                  )));
                                                      bool isCorrect = true;
                                                      try {
                                                        Map<String, dynamic>
                                                            data =
                                                            await uploadSmartFenceData(
                                                                    idInt,
                                                                    "S",
                                                                    "Y",
                                                                    name)
                                                                .whenComplete(() =>
                                                                    Navigator.of(
                                                                            context,
                                                                            rootNavigator:
                                                                                true)
                                                                        .pop());
                                                        if (data['status'] ==
                                                            'Y') {
                                                          SmartFenceData obj =
                                                              Provider.of<Data>(
                                                                      context,
                                                                      listen:
                                                                          false)
                                                                  .smartData[name];
                                                          obj.smartFenceActivate =
                                                              true;
                                                          Provider.of<Data>(
                                                                  context,
                                                                  listen: false)
                                                              .changeSmartFenceData(
                                                                  obj);
                                                        }
                                                        _textMe(0, name);
                                                      } catch (error) {
                                                        print('3$error');
                                                        isCorrect = false;
                                                        await Future.delayed(
                                                                Duration(
                                                                    milliseconds:
                                                                        100))
                                                            .whenComplete(() =>
                                                                showDialog(
                                                                    context:
                                                                        context,
                                                                    builder: (BuildContext
                                                                            context) =>
                                                                        CupertinoAlertDialog(
                                                                          title:
                                                                              Text("Wrong range or location."),
                                                                          actions: <
                                                                              Widget>[
                                                                            CupertinoDialogAction(
                                                                              onPressed: () {
                                                                                Navigator.of(context).pop();
                                                                              },
                                                                              isDefaultAction: true,
                                                                              child: Text('Cancel'),
                                                                            ),
                                                                            CupertinoDialogAction(
                                                                              onPressed: () {
                                                                                Navigator.of(context).pop();
                                                                              },
                                                                              child: Text("Try Again"),
                                                                            )
                                                                          ],
                                                                        )));
                                                      }
                                                      if (isCorrect) {
                                                        Navigator.of(context)
                                                            .popUntil((route) =>
                                                                route.isFirst);
                                                      } else {
                                                        Navigator.of(context)
                                                            .pop();
                                                      }
                                                    },
                                                    isDefaultAction: true,
                                                    child: Text('No'),
                                                  ),
                                                  CupertinoDialogAction(
                                                    onPressed: () async {
                                                      int idInt = int.parse(id);
                                                      showDialog(
                                                          context: context,
                                                          barrierDismissible:
                                                              false,
                                                          builder: (context) =>
                                                              WillPopScope(
                                                                  onWillPop: () =>
                                                                      Future.value(
                                                                          false),
                                                                  child:
                                                                      CupertinoActivityIndicator(
                                                                    radius: 20,
                                                                    animating:
                                                                        true,
                                                                  )));
                                                      bool isCorrect = true;
                                                      try {
                                                        Map<String, dynamic>
                                                            data =
                                                            await uploadSmartFenceData(
                                                                    idInt,
                                                                    "S",
                                                                    "Y",
                                                                    name)
                                                                .whenComplete(() =>
                                                                    Navigator.of(
                                                                            context,
                                                                            rootNavigator:
                                                                                true)
                                                                        .pop());
                                                        if (data['status'] ==
                                                            'Y') {
                                                          SmartFenceData obj =
                                                              Provider.of<Data>(
                                                                      context,
                                                                      listen:
                                                                          false)
                                                                  .smartData[name];
                                                          obj.smartFenceActivate =
                                                              true;
                                                          Provider.of<Data>(
                                                                  context,
                                                                  listen: false)
                                                              .changeSmartFenceData(
                                                                  obj);
                                                        }
                                                        _textMe(1, name);
                                                      } catch (error) {
                                                        print('4$error');
                                                        isCorrect = false;
                                                        await Future.delayed(
                                                                Duration(
                                                                    milliseconds:
                                                                        100))
                                                            .whenComplete(() =>
                                                                showDialog(
                                                                    context:
                                                                        context,
                                                                    builder: (BuildContext
                                                                            context) =>
                                                                        CupertinoAlertDialog(
                                                                          title:
                                                                              Text("Wrong range or location."),
                                                                          actions: <
                                                                              Widget>[
                                                                            CupertinoDialogAction(
                                                                              onPressed: () {
                                                                                Navigator.of(context).pop();
                                                                              },
                                                                              isDefaultAction: true,
                                                                              child: Text('Cancel'),
                                                                            ),
                                                                            CupertinoDialogAction(
                                                                              onPressed: () {
                                                                                Navigator.of(context).pop();
                                                                              },
                                                                              child: Text("Try Again"),
                                                                            )
                                                                          ],
                                                                        )));
                                                      }
                                                      if (isCorrect) {
                                                        Navigator.of(context)
                                                            .popUntil((route) =>
                                                                route.isFirst);
                                                      } else {
                                                        Navigator.of(context)
                                                            .pop();
                                                      }
                                                    },
                                                    child: Text("Yes"),
                                                  )
                                                ],
                                              ));
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Activate',
                                        style: TextStyle(fontSize: 20),
                                      ),
                                    )),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              body: GoogleMap(
                myLocationEnabled: true,
                onMapCreated: (mapController) {
                  _mapController = mapController;
                },
                initialCameraPosition: CameraPosition(
                    target: Provider.of<Data>(context)
                                .smartData[name]
                                .smartFenceLocation ==
                            null
                        ? LatLng(location.latitude - 0.001, location.longitude)
                        : Provider.of<Data>(context)
                            .smartData[name]
                            .smartFenceLocation,
                    zoom: 16),
                circles: Set<Circle>.of(circles.values),
              ),
            ),
          );
        } else {
          return Scaffold(
              body: Center(
                  child: CupertinoActivityIndicator(
            radius: 20,
            animating: true,
          )));
        }
      },
    );
  }
}

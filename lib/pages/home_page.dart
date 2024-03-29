import 'dart:convert';
import 'dart:math';

import 'package:app_settings/app_settings.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ion_it/pages/findmycar_page.dart';
import 'package:ion_it/pages/passing_by_record_page.dart';
import 'package:ion_it/pages/select_vehicle.dart';
import 'package:ion_it/pages/select_vehicle_focus.dart';
import 'package:ion_it/pages/select_vehicle_history.dart';
import 'package:ion_it/pages/select_vehicle_home.dart';
import 'package:ion_it/pages/select_vehicle_immo.dart';
import 'package:ion_it/pages/setting.dart';
import 'dart:async';
import 'package:ion_it/widgets/customInfoWidget.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:ion_it/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Position {
  var latitude;
  var longitude;
  Position(var latitude, var longitude) {
    this.latitude = latitude;
    this.longitude = longitude;
  }
}

class PointObject {
  String name;
  LatLng location;
}

class HomePage extends StatefulWidget {
  final String jsonData;
  final LatLng myLocation;
  const HomePage({Key key, @required this.jsonData, @required this.myLocation})
      : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  StreamSubscription _mapIdleSubscription;
  InfoWidgetRoute _infoWidgetRoute;
  GoogleMapController _mapController;
  Timer _timer;
  int _start = 60;
  Map<String, String> hintText = {
    'en':
        'Please allow the location services and permission.\nIf your location permission is \n" Denied Forever ", go to settings and change it.',
    'zh': '請打開定位服務並允許位置權限。\n如果裝置位置權限為\n「永不」，請到設定中變更為其他選擇。'
  };

  Map<String, List<String>> btnText = {
    'en': ['settings', 'allow'],
    'zh': ['設定', '允許'],
  };

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    if (_timer != null) {
      _timer.cancel();
      _start = 60;
    }
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) async {
        if (_start == 0) {
          if (_infoWidgetRoute != null) {
            Navigator.of(context).pop();
          }
          timer.cancel();
          await refreshPage();
          startTimer();
        } else {
          _start--;
        }
      },
    );
  }

  void _determinePosition() async {
    Location location = new Location();
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;
    _serviceEnabled = await location.serviceEnabled();
    _permissionGranted = await location.hasPermission();
    if ((!_serviceEnabled) ||
        (_permissionGranted != PermissionStatus.granted)) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          actions: [
            TextButton(
                onPressed: AppSettings.openLocationSettings,
                child: Text(
                    Provider.of<Data>(context, listen: false).localeName == 'zh'
                        ? btnText['zh'][0]
                        : btnText['en'][0])),
            TextButton(
                onPressed: () async {
                  if (!_serviceEnabled) {
                    _serviceEnabled = await location.requestService();
                  }
                  if (_permissionGranted == PermissionStatus.denied) {
                    _permissionGranted = await location.requestPermission();
                  }
                  Navigator.of(context).pop();
                },
                child: Text(
                    Provider.of<Data>(context, listen: false).localeName == 'zh'
                        ? btnText['zh'][1]
                        : btnText['en'][1])),
          ],
          title: Text(
              Provider.of<Data>(context, listen: false).localeName == 'zh'
                  ? '需要定位權限'
                  : 'Location Services Needed'),
          content: Text(
            Provider.of<Data>(context, listen: false).localeName == 'zh'
                ? hintText['zh']
                : hintText['en'],
          ),
        ),
        barrierDismissible: false,
      );
    }
    _serviceEnabled = await location.serviceEnabled();
    _permissionGranted = await location.hasPermission();
    if (_serviceEnabled && _permissionGranted == PermissionStatus.granted) {
      _locationData = await location.getLocation();
      await _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_locationData.latitude, _locationData.longitude),
            zoom: 16,
          ),
        ),
      );
    }
  }

  Future<String> getAddress(LatLng point) async {
    String lang = Provider.of<Data>(context, listen: false).localeName == 'zh'
        ? "zh-TW"
        : "en";
    String uri = "https://web.onlinetraq.com/module/APIv1/006-1.php";
    var data = json.decode(widget.jsonData);
    var jsonData = json.encode({
      "server": data['server'],
      "user": data['user'],
      "pass": data['pass'],
      "lat": point.latitude,
      "lng": point.longitude,
      "lang": lang,
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

  void refreshPage() async {
    if (Provider.of<Data>(context, listen: false).descriptors.isNotEmpty) {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
              onWillPop: () => Future.value(false),
              child: CupertinoActivityIndicator(
                radius: 20,
                animating: true,
              )));
      Map<dynamic, List> vehiclesData = await getVehicles();
      for (var item
          in Provider.of<Data>(context, listen: false).descriptors.entries) {
        await makeMarker(item.key, vehiclesData[item.key]);
      }
      Navigator.of(context, rootNavigator: true).pop();
      combineMarker(1);
    }
  }

  void triggerInfoWindow() {
    _mapIdleSubscription?.cancel();
    _mapIdleSubscription = Future.delayed(Duration(milliseconds: 150))
        .asStream()
        .listen((_) async {
      if (_infoWidgetRoute != null) {
        Navigator.of(context, rootNavigator: true)
            .push(_infoWidgetRoute)
            .then<void>(
          (newValue) {
            _infoWidgetRoute = null;
          },
        );
      }
    });
  }

  void makeMarker(String key, List value) async {
    //get address by LatLng
    List<String> latlng = value[1].split(',');
    var point = LatLng(double.parse(latlng[0]), double.parse(latlng[1]));
    var address = await getAddress(point);

    Provider.of<Data>(context, listen: false).descriptors[key].id = key;
    Provider.of<Data>(context, listen: false).descriptors[key].value = value;
    Provider.of<Data>(context, listen: false).descriptors[key].address =
        address;
  }

  Future<Map<dynamic, List>> getVehicles() async {
    Map<dynamic, List> allVehiclesData = <dynamic, List>{};
    List<String> idList = [];

    String uri = "https://web.onlinetraq.com/module/APIv1/003-1.php";
    FormData formData = FormData.fromMap({'data': widget.jsonData});
    var response = await Dio().post(uri, data: formData);
    Map<String, dynamic> data = json.decode(response.data);

    for (var item in data['data']) {
      List value = [];
      value.add(item['name']);
      allVehiclesData[item['id']] = value;
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
    return allVehiclesData;
  }

  void combineMarker(int type) async {
    if (Provider.of<Data>(context, listen: false).descriptors.isNotEmpty) {
      for (var item
          in Provider.of<Data>(context, listen: false).descriptors.entries) {
        final MarkerId markiId = MarkerId(item.value.id);
        PointObject point = new PointObject();
        List<String> latlng = item.value.value[1].split(',');
        point.location =
            LatLng(double.parse(latlng[0]), double.parse(latlng[1]));

        var obj;
        Marker marker = Marker(
          onTap: () async {
            // Provider.of<Data>(context,listen: false).changeIsShowingInfoWindow();
            final RenderBox renderBox = context.findRenderObject();
            Rect _itemRect =
                renderBox.localToGlobal(Offset.zero) & renderBox.size;

            _infoWidgetRoute = InfoWidgetRoute(
              child: Container(
                child: Column(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.black26, width: 1),
                          ),
                        ),
                        padding: EdgeInsets.only(right: 17, left: 17),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "${item.value.value[0]} ",
                                maxLines: 2,
                                style: TextStyle(
                                    fontSize: 13 /
                                        MediaQuery.of(context).textScaleFactor,
                                    fontFamily: 'Arial'),
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            Container(
                              child: Row(
                                children: [
                                  Container(
                                      height: 20,
                                      child: SvgPicture.asset(
                                        'assets/svg/clock.svg',
                                      )),
                                  Text(
                                    item.value.value[3],
                                    maxLines: 2,
                                    style: TextStyle(
                                        fontSize: 13 /
                                            MediaQuery.of(context)
                                                .textScaleFactor,
                                        fontFamily: 'Arial'),
                                    overflow: TextOverflow.visible,
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.black26, width: 1),
                          ),
                        ),
                        padding: EdgeInsets.only(right: 17, left: 17),
                        child: Row(
                          children: [
                            Container(
                                height: 20,
                                child: SvgPicture.asset(
                                  'assets/svg/locate_infowindow.svg',
                                )),
                            Expanded(
                              child: Text(
                                item.value.address == null
                                    ? ''
                                    : item.value.address,
                                maxLines: 2,
                                style: TextStyle(
                                    fontSize: 13 /
                                        MediaQuery.of(context).textScaleFactor,
                                    fontFamily: 'Arial'),
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.black26, width: 1),
                          ),
                        ),
                        padding: EdgeInsets.only(right: 17, left: 17),
                        child: Row(
                          children: [
                            Container(
                                height: 20,
                                child: SvgPicture.asset(
                                  'assets/svg/date.svg',
                                )),
                            SizedBox(
                              width: 10,
                            ),
                            item.value.value[2] == 'Y'
                                ? Text(
                                    item.value.value[4],
                                    maxLines: 2,
                                    style: TextStyle(
                                        fontSize: 13 /
                                            MediaQuery.of(context)
                                                .textScaleFactor,
                                        fontFamily: 'Arial'),
                                    overflow: TextOverflow.visible,
                                  )
                                : Text(
                                    'Unknow',
                                    maxLines: 2,
                                    style: TextStyle(
                                        fontSize: 13 /
                                            MediaQuery.of(context)
                                                .textScaleFactor,
                                        fontFamily: 'Arial'),
                                    overflow: TextOverflow.visible,
                                  ),
                            Expanded(child: SizedBox()),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.black26, width: 1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(
                                width: 30,
                                child: item.value.value[6] == 'Y'
                                    ? SvgPicture.asset(
                                        'assets/svg/overspeed_on.svg',
                                      )
                                    : SvgPicture.asset(
                                        'assets/svg/overspeed_off.svg',
                                      )),
                            Container(
                                width: 30,
                                child: item.value.value[5] == 'D'
                                    ? SvgPicture.asset(
                                        'assets/svg/driving.svg',
                                      )
                                    : item.value.value[5] == 'S'
                                        ? SvgPicture.asset(
                                            'assets/svg/stop.svg',
                                          )
                                        : item.value.value[5] == 'I'
                                            ? SvgPicture.asset(
                                                'assets/svg/idle.svg',
                                              )
                                            : SvgPicture.asset(
                                                'assets/svg/drag.svg',
                                              )),
                            Container(
                                width: 30,
                                child: item.value.value[7] == 'Y'
                                    ? SvgPicture.asset(
                                        'assets/svg/switch_on.svg',
                                      )
                                    : SvgPicture.asset(
                                        'assets/svg/switch_off.svg',
                                      )),
                            Container(
                                width: 30,
                                child: item.value.value[8] == 'Y'
                                    ? SvgPicture.asset(
                                        'assets/svg/engine_on.svg',
                                      )
                                    : SvgPicture.asset(
                                        'assets/svg/engine_off.svg',
                                      )),
                            Container(
                                width: 30,
                                child: item.value.value[10] == 'Y'
                                    ? SvgPicture.asset(
                                        'assets/svg/battery_on.svg',
                                      )
                                    : SvgPicture.asset(
                                        'assets/svg/battery_off.svg',
                                      )),
                            Container(
                              width: 30,
                              child: item.value.value[11] == 'Y'
                                  ? SvgPicture.asset(
                                      'assets/svg/smartfence_icon_on.svg',
                                    )
                                  : SvgPicture.asset(
                                      'assets/svg/smartfence_icon_off.svg',
                                    ),
                            ),
                            Container(
                                width: 30,
                                child: item.value.value[9] == 'Y'
                                    ? SvgPicture.asset(
                                        'assets/svg/emergency_on.svg',
                                      )
                                    : SvgPicture.asset(
                                        'assets/svg/emergency_off.svg',
                                      )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              buildContext: context,
              textStyle: const TextStyle(
                fontSize: 20,
                color: Colors.black,
              ),
              mapsWidgetSize: _itemRect,
            );
            await Future.delayed(Duration(milliseconds: 666));
            await _mapController.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(point.location.latitude - 1,
                      point.location.longitude - 1),
                  zoom: 18,
                ),
              ),
            );
            await _mapController.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(point.location.latitude - 0.0001,
                      point.location.longitude),
                  zoom: 20,
                ),
              ),
            );
            triggerInfoWindow();
          },
          icon: item.value.descriptor,
          markerId: markiId,
          position: point.location,
        );
        Provider.of<Data>(context, listen: false)
            .changeMarker(item.value.id, marker);
      }
      if (!Provider.of<Data>(context, listen: false).focus) {
        LatLngBounds bounds = getBounds(
            Provider.of<Data>(context, listen: false).markers.values.toList());
        CameraUpdate centerPoint = CameraUpdate.newLatLngBounds(bounds, 50);
        if (type == 0) {
          //0:from select car page,1:auto refresh
          await Future.delayed(Duration(milliseconds: 666));
          await _mapController.animateCamera(centerPoint);
        }
      } else {
        await getFocus();
      }
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

  void getFocus() async {
    LatLng position;
    String id = '';
    if (Provider.of<Data>(context, listen: false).focus) {
      Provider.of<Data>(context, listen: false)
          .descriptors
          .forEach((key, value) {
        if (Provider.of<Data>(context, listen: false).focusVehicleSelect ==
            value.value[0]) {
          id = value.id;
          List<String> latlng = value.value[1].split(',');
          position = LatLng(double.parse(latlng[0]), double.parse(latlng[1]));
        }
      });

      if (position != null && id.isNotEmpty) {
        await Future.delayed(Duration(milliseconds: 666));
        // await _mapController.animateCamera(CameraUpdate.newCameraPosition(
        //     CameraPosition(
        //         target: LatLng(position.latitude - 1, position.longitude - 1),
        //         zoom: 18)));
        // await _mapController.animateCamera(CameraUpdate.newCameraPosition(
        //     CameraPosition(
        //         target: LatLng(position.latitude - 0.0001, position.longitude),
        //         zoom: 16.5)));
        Provider.of<Data>(context, listen: false).markers[id].onTap();
      }
    } else {
      LatLngBounds bounds = getBounds(
          Provider.of<Data>(context, listen: false).markers.values.toList());
      CameraUpdate centerPoint = CameraUpdate.newLatLngBounds(bounds, 50);
      await Future.delayed(Duration(milliseconds: 666));
      await _mapController.animateCamera(centerPoint);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    startTimer();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _mapController.setMapStyle("[]");
      setState(() {});
    }
  }

  Future<List> getLoginData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List loginData = prefs.getStringList('accountData');
    return loginData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                  color: Color.fromRGBO(0, 113, 188, 1),
                  height: MediaQuery.of(context).size.height / 12,
                  child: Center(
                      child: Text(
                    'Functions',
                    style: TextStyle(
                        fontFamily: 'Arial', fontSize: 24, color: Colors.white),
                  ))),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      colors: [
                        Color.fromRGBO(144, 255, 192, 1),
                        Color.fromRGBO(98, 213, 205, 1),
                        Color.fromRGBO(0, 124, 233, 1),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _timer.cancel();
                          Navigator.pop(context);
                          Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SelectVehicle(
                                          jsonData: widget.jsonData)))
                              .then((value) {
                            startTimer();
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: Colors.white, width: 1))),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 16),
                            child: Center(
                              child: Row(
                                children: [
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width / 7,
                                    child: SvgPicture.asset(
                                      'assets/svg/smartfence.svg',
                                      height: 30,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Smart Fence',
                                      maxLines: 2,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontFamily: 'Arial'),
                                      overflow: TextOverflow.visible,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _timer.cancel();
                          Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          FindMyCar(jsonData: widget.jsonData)))
                              .then((value) {
                            setState(() {
                              startTimer();
                            });
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.white, width: 1),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 16),
                            child: Center(
                              child: Row(
                                children: [
                                  Container(
                                      width:
                                          MediaQuery.of(context).size.width / 7,
                                      child: SvgPicture.asset(
                                        'assets/svg/findmycar.svg',
                                        height: 30,
                                      )),
                                  Expanded(
                                    child: Text(
                                      'Find My Car',
                                      maxLines: 2,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontFamily: 'Arial'),
                                      overflow: TextOverflow.visible,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _timer.cancel();
                          Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SelectVehicleImmo(
                                          jsonData: widget.jsonData)))
                              .then((value) {
                            startTimer();
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: Colors.white, width: 1))),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 16),
                            child: Center(
                              child: Row(
                                children: [
                                  Container(
                                      width:
                                          MediaQuery.of(context).size.width / 7,
                                      child: SvgPicture.asset(
                                        'assets/svg/immobiliser.svg',
                                        height: 30,
                                      )),
                                  Expanded(
                                    child: Text(
                                      'Immobiliser',
                                      maxLines: 2,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontFamily: 'Arial'),
                                      overflow: TextOverflow.visible,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _timer.cancel();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PassingByRecord(
                                jsonData: widget.jsonData,
                                myLocation: widget.myLocation,
                              ),
                            ),
                          ).then((value) {
                            setState(() {
                              startTimer();
                            });
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: Colors.white, width: 1))),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 16),
                            child: Center(
                              child: Row(
                                children: [
                                  Container(
                                      width:
                                          MediaQuery.of(context).size.width / 7,
                                      child: SvgPicture.asset(
                                        'assets/svg/passingbyrecord.svg',
                                        height: 30,
                                      )),
                                  Expanded(
                                    child: Text(
                                      'Passing-by Record',
                                      maxLines: 2,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontFamily: 'Arial'),
                                      overflow: TextOverflow.visible,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _timer.cancel();
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SelectVehicleHistory(
                                      jsonData: widget.jsonData))).then(
                              (value) {
                            startTimer();
                          });
                        },
                        child: Container(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 16),
                            child: Center(
                              child: Row(
                                children: [
                                  Container(
                                      width:
                                          MediaQuery.of(context).size.width / 7,
                                      child: SvgPicture.asset(
                                        'assets/svg/history.svg',
                                        height: 30,
                                      )),
                                  Expanded(
                                    child: Text(
                                      'History',
                                      maxLines: 2,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontFamily: 'Arial'),
                                      overflow: TextOverflow.visible,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(child: Container())
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(247, 247, 247, 1),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: SvgPicture.asset(
              'assets/svg/menu.svg',
              height: 15,
            ),
            onPressed: () {
              Scaffold.of(ctx).openDrawer();
            },
          ),
        ),
        title: Center(
            child: Image.asset(
          'assets/images/title.png',
          scale: 5,
        )),
        actions: [
          IconButton(
            icon: Provider.of<Data>(context).focus
                ? Image.asset(
                    'assets/images/focus_on.png',
                    height: 30,
                  )
                : Image.asset(
                    'assets/images/focus_off.png',
                    height: 30,
                  ),
            onPressed: () async {
              _timer.cancel();
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SelectVehicleFocus(
                            descriptors:
                                Provider.of<Data>(context, listen: false)
                                    .descriptors
                                    .entries
                                    .toList(),
                          ))).then((value) {
                if (Provider.of<Data>(context, listen: false)
                    .descriptors
                    .isNotEmpty) {
                  getFocus();
                }
                setState(() {
                  startTimer();
                });
              });
            },
          ),
          IconButton(
            icon: SvgPicture.asset(
              'assets/svg/setting.svg',
              height: 30,
            ),
            onPressed: () async {
              _timer.cancel();
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          Setting(jsonData: widget.jsonData))).then((value) {
                setState(() {
                  startTimer();
                });
              });
            },
          ),
        ],
      ),
      body: GoogleMap(
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        markers: Set<Marker>.of(Provider.of<Data>(context).markers.values),
        zoomGesturesEnabled: true,
        mapToolbarEnabled: false,
        onMapCreated: (mapController) async {
          _mapController = mapController;
          await _mapController.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
              target: widget.myLocation == null
                  ? LatLng(24.96538069686663, 121.43875091494725)
                  : widget.myLocation,
              zoom: 17,
            ),
          ));
        },
        compassEnabled: false,
        initialCameraPosition: CameraPosition(
          target: widget.myLocation == null
              ? LatLng(24.96538069686663, 121.43875091494725)
              : widget.myLocation,
          zoom: 16.5,
        ),
        zoomControlsEnabled: false,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'myLocation',
            backgroundColor: Colors.white,
            child: Icon(
              Icons.my_location_rounded,
              size: 35,
              color: Colors.black,
            ),
            onPressed: () async {
              await _determinePosition();
            },
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.015,
          ),
          FloatingActionButton(
            heroTag: 'myCars',
            child: Icon(
              Icons.directions_car_rounded,
              size: 35,
            ),
            onPressed: () {
              _timer.cancel();
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SelectVehicleHome(
                            jsonData: widget.jsonData,
                          ))).then((value) {
                setState(() {
                  combineMarker(0);
                  startTimer();
                });
              });
            },
          ),
        ],
      ),
    );
  }
}

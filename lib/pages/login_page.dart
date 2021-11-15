import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ion_it/pages/home_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:ion_it/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart';
import 'package:app_settings/app_settings.dart';

class Position {
  var latitude;
  var longitude;
  Position(var latitude, var longitude) {
    this.latitude = latitude;
    this.longitude = longitude;
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key key}) : super(key: key);
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String memberJson;
  Future<Position> getLocation;
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final TextEditingController serverController = TextEditingController();
  Map<String, String> hintText = {
    'en':
        'Please allow the location services and permission.\nIf your location permission is \n" Denied Forever ", go to settings and change it.',
    'zh': '請打開定位服務並允許位置權限。\n如果裝置位置權限為\n「永不」，請到設定中變更為其他選擇。'
  };

  Map<String, List<String>> btnText = {
    'en': ['settings', 'allow'],
    'zh': ['設定', '允許'],
  };

  Future<bool> FCMSend() async {
    String serverKey =
        "AAAAJoiuPw4:APA91bGvkvIcQ_L_KU3g5ER1Mok95qMnFW-MrVLxw2RF1dSkKu1O3nVzQfzp3ropJ5y-Zydiu5NiI9ZlxAx5EqU9C8C4T8nf_PMxJKlX8unX3iBoXYkdhiMLk1zgujRSl1XT4M9CU_mP";
    String uri = "https://fcm.googleapis.com/fcm/send";
    String token = Provider.of<Data>(context, listen: false).token;
    var jsonData = json.encode({
      "to": "$token",
      "notification": {"title": "test", "body": "666666"},
    });

    try {
      var response = await Dio().post(uri,
          data: jsonData,
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: "key=$serverKey",
              },
              contentType: 'application/json',
              followRedirects: false,
              validateStatus: (status) {
                print(status);
                return true;
              }));
      print(response.data);
      Map<String, dynamic> data = json.decode(response.data);
    } catch (err) {
      print(err);
    }
  }

  Future<bool> updateFCMToken(String server, String user, String pass) async {
    String result = '';
    String uri = "https://web.onlinetraq.com/module/APIv1/005-2fcm.php";
    String token = Provider.of<Data>(context, listen: false).token;
    int fromType = Platform.isIOS ? 1 : 2;
    var jsonData = json.encode({
      "server": server,
      "user": user,
      "pass": pass,
      "token": token,
      "fromtype": fromType,
    });

    FormData formData = FormData.fromMap({'data': jsonData});
    print(formData.fields);
    var statusCode;

    try {
      var response = await Dio().post(uri,
          data: formData,
          options: Options(
              followRedirects: false,
              validateStatus: (status) {
                statusCode = status;
                return true;
              }));
      print(response.data);
      Map<String, dynamic> data = json.decode(response.data);
      (statusCode == 200) && (data['result'] == 'S')
          ? result = 'Y'
          : result = 'N';
    } catch (err) {}
    if (result == 'Y') {
      return true;
    } else {
      return false;
    }
  }

  Future<String> postLoginApi(String server, String user, String pass) async {
    String result = '';
    String uri = "https://web.onlinetraq.com/module/APIv1/002-2.php";
    var jsonData = json.encode({"server": server, "user": user, "pass": pass});
    FormData formData = FormData.fromMap({'data': jsonData});
    var statusCode;

    try {
      var response = await Dio().post(uri,
          data: formData,
          options: Options(
              followRedirects: false,
              validateStatus: (status) {
                statusCode = status;
                return true;
              }));
      Map<String, dynamic> data = json.decode(response.data);

      (statusCode == 200) && (data['result'] == 'S')
          ? result = 'Y'
          : result = 'N';
      if (result == 'Y') {
        List<String> accountData = [server, user, pass, jsonData];
        memberJson = jsonData;
        Provider.of<Data>(context, listen: false)
            .changeLoginData(server, user, pass);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setStringList('loginData', accountData);
      }
      return result;
    } catch (error) {
      result = 'E';
      await showDialog(
          context: context,
          builder: (BuildContext context) => CupertinoAlertDialog(
                title: Text("Network Error"),
                actions: <Widget>[
                  CupertinoDialogAction(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    isDefaultAction: true,
                    child: Text('OK'),
                  ),
                ],
              ));
      return result;
    }
  }

  Future<List> getLoginData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List loginData = prefs.getStringList('loginData');
    if (loginData != null) {
      serverController.text = loginData[0];
      userController.text = loginData[1];
      passController.text = loginData[2];
    }
    return loginData;
  }

  Future<bool> findServiceEnable(Location location) async {
    bool _serviceEnabled = false;
    try {
      _serviceEnabled = await location.serviceEnabled();
    } on PlatformException catch (err) {
      _serviceEnabled = await findServiceEnable(location);
    }
    return _serviceEnabled;
  }

  Future<Position> _determinePosition() async {
    Location location = new Location();
    Position position;
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    _serviceEnabled = await findServiceEnable(location);
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
                    if (!_serviceEnabled) {
                      position = null;
                    }
                  }
                  if (_permissionGranted == PermissionStatus.denied) {
                    _permissionGranted = await location.requestPermission();
                    if (_permissionGranted != PermissionStatus.granted) {
                      position = null;
                    }
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

    //handle service Platform error
    _serviceEnabled = await findServiceEnable(location);
    _permissionGranted = await location.hasPermission();

    if (_serviceEnabled && _permissionGranted == PermissionStatus.granted) {
      _locationData = await location.getLocation();
      position = new Position(_locationData.latitude, _locationData.longitude);
    }
    return position;
  }

  @override
  void initState() {
    getLoginData();
    getLocation = _determinePosition();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Position>(
        future: getLocation,
        builder: (context, snapshot) {
          Position currentPosition;
          if (snapshot.connectionState == ConnectionState.done) {
            currentPosition = snapshot.data;
            return Scaffold(
              resizeToAvoidBottomInset: false,
              backgroundColor: Color.fromRGBO(247, 247, 247, 1),
              body: SafeArea(
                child: Stack(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          child: Image.asset(
                            'assets/images/bground.png',
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height / 30,
                        ),
                        GestureDetector(
                          onTap: () async {
                            await FCMSend();
                          },
                          child: Container(
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/svg/mark.svg',
                              ),
                            ),
                          ),
                        ),
                        //Text('iON-it',style: TextStyle(fontFamily: 'Arial',color: Color.fromRGBO(0, 124, 233, 1),fontSize: 36),),
                        SizedBox(
                          height: MediaQuery.of(context).size.height / 50,
                        ),
                        Image.asset(
                          'assets/images/title.png',
                          scale: 5,
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height / 8,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          height: MediaQuery.of(context).size.height /
                              15 *
                              MediaQuery.of(context)
                                  .textScaleFactor
                                  .clamp(1.0, 1.8),
                          width: MediaQuery.of(context).size.width / 1.2,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20, right: 24),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    onChanged: (text) {
                                      serverController.text =
                                          text.toUpperCase();
                                      serverController.selection =
                                          TextSelection.fromPosition(
                                              TextPosition(
                                                  offset: serverController
                                                      .text.length));
                                    },
                                    controller: serverController,
                                    style: TextStyle(
                                        fontSize: 22,
                                        color: Color.fromRGBO(0, 113, 188, 1)),
                                    maxLines: 1,
                                    decoration: InputDecoration(
                                        hintStyle: TextStyle(
                                            fontSize: 22,
                                            color: Colors.black12),
                                        border: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        disabledBorder: InputBorder.none,
                                        contentPadding: EdgeInsets.only(
                                            left: 15,
                                            bottom: 11,
                                            top: 11,
                                            right: 15),
                                        hintText: "Server"),
                                  ),
                                ),
                                Container(
                                    height:
                                        MediaQuery.of(context).size.height / 30,
                                    child: SvgPicture.asset(
                                        'assets/svg/server.svg',
                                        color: Color.fromRGBO(0, 113, 188, 1)))
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height / 40,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          height: MediaQuery.of(context).size.height /
                              15 *
                              MediaQuery.of(context)
                                  .textScaleFactor
                                  .clamp(1.0, 1.8),
                          width: MediaQuery.of(context).size.width / 1.2,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20, right: 24),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: userController,
                                    style: TextStyle(
                                        fontSize: 22,
                                        color: Color.fromRGBO(0, 113, 188, 1)),
                                    maxLines: 1,
                                    decoration: InputDecoration(
                                        hintStyle: TextStyle(
                                            fontSize: 22,
                                            color: Colors.black12),
                                        border: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        disabledBorder: InputBorder.none,
                                        contentPadding: EdgeInsets.only(
                                            left: 15,
                                            bottom: 11,
                                            top: 11,
                                            right: 15),
                                        hintText: "User Name"),
                                  ),
                                ),
                                Container(
                                    height:
                                        MediaQuery.of(context).size.height / 30,
                                    child: SvgPicture.asset(
                                        'assets/svg/user.svg',
                                        color: Color.fromRGBO(0, 113, 188, 1)))
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height / 40,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          height: MediaQuery.of(context).size.height /
                              15 *
                              MediaQuery.of(context)
                                  .textScaleFactor
                                  .clamp(1.0, 1.8),
                          width: MediaQuery.of(context).size.width / 1.2,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20, right: 28),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: passController,
                                    style: TextStyle(
                                        fontSize: 22,
                                        color: Color.fromRGBO(0, 113, 188, 1)),
                                    maxLines: 1,
                                    decoration: InputDecoration(
                                        hintStyle: TextStyle(
                                            fontSize: 22,
                                            color: Colors.black12),
                                        border: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        disabledBorder: InputBorder.none,
                                        contentPadding: EdgeInsets.only(
                                            left: 15,
                                            bottom: 11,
                                            top: 11,
                                            right: 15),
                                        hintText: "Password"),
                                  ),
                                ),
                                Container(
                                    height:
                                        MediaQuery.of(context).size.height / 30,
                                    child: SvgPicture.asset(
                                        'assets/svg/passwd.svg',
                                        color: Color.fromRGBO(0, 113, 188, 1)))
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height / 50,
                        ),
                        GestureDetector(
                            onTap: () async {
                              showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => WillPopScope(
                                      onWillPop: () => Future.value(false),
                                      child: CupertinoActivityIndicator(
                                        radius: 20,
                                        animating: true,
                                      )));
                              String result = await postLoginApi(
                                      serverController.text,
                                      userController.text,
                                      passController.text)
                                  .whenComplete(() async {
                                Navigator.pop(context);
                              });
                              if (result == 'Y') {
                                if (Provider.of<Data>(context, listen: false)
                                        .pushNotSwitch &&
                                    Provider.of<Data>(context, listen: false)
                                            .token !=
                                        'invalid') {
                                  await updateFCMToken(serverController.text,
                                      userController.text, passController.text);
                                }
                                if (currentPosition != null) {
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => HomePage(
                                          jsonData: memberJson,
                                          myLocation: LatLng(
                                              currentPosition.latitude,
                                              currentPosition.longitude),
                                        ),
                                      ));
                                } else {
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => HomePage(
                                          jsonData: memberJson,
                                          myLocation: null,
                                        ),
                                      ));
                                }
                              } else {
                                if (result == 'N') {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          CupertinoAlertDialog(
                                            title: Text(
                                                "Wrong server, user name or password."),
                                            actions: <Widget>[
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
                                          ));
                                }
                              }
                            },
                            child: Container(
                              height: MediaQuery.of(context).size.height / 9,
                              width: MediaQuery.of(context).size.width / 1,
                              child: Center(
                                child: SvgPicture.asset(
                                  'assets/svg/login.svg',
                                ),
                              ),
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            );
          } else {
            return Scaffold(
                body: Container(
                    child: Center(
                        child: CupertinoActivityIndicator(
                            radius: 20, animating: true))));
          }
        });
  }
}

import 'dart:convert';
import 'package:geolocator/geolocator.dart';
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

class LoginPage extends StatefulWidget {
  final bool fromBegin;
  const LoginPage({Key key, @required this.fromBegin}) : super(key: key);
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String memberJson;
  Future<Position> getLocation;
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final TextEditingController serverController = TextEditingController();

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
    bool serviceEnabled = false;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await _checkLocationServiceEnable();
    if (!serviceEnabled) {
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
                        Container(
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/svg/mark.svg',
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
                          height: MediaQuery.of(context).size.height / 15,
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
                          height: MediaQuery.of(context).size.height / 15,
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
                          height: MediaQuery.of(context).size.height / 15,
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

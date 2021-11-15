import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ion_it/main.dart';
import 'package:ion_it/pages/event_log.dart';
import 'package:ion_it/pages/login_page.dart';
import 'package:ion_it/pages/select_vehicle_diagnosis.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Setting extends StatefulWidget {
  final String jsonData;
  const Setting({Key key, @required this.jsonData}) : super(key: key);
  @override
  _SettingState createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  Future<bool> isShareNotificationOn() async {
    bool isNotificationOn = false;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isNotificationOn = prefs.getBool('notification');

    return isNotificationOn;
  }

  Future<bool> changeShareNotification({bool newValue}) async {
    bool result = false;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    result = await prefs.setBool('notification', newValue);
    return result;
  }

  Future<bool> updateFCMToken() async {
    String server = Provider.of<Data>(context, listen: false).server;
    String user = Provider.of<Data>(context, listen: false).user;
    String pass = Provider.of<Data>(context, listen: false).pass;
    String result = '';
    String uri = "https://web.onlinetraq.com/module/APIv1/005-2fcm.php";
    String token = Provider.of<Data>(context, listen: false).token;
    int fromType = Platform.isIOS ? 1 : 2;
    var jsonData = json.encode({
      "server": server,
      "user": user,
      "pass": pass,
      "token": token,
      "fromtype": fromType
    });
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
      print(response.data);
      Map<String, dynamic> data = json.decode(response.data);
      (statusCode == 200) && (data['result'] == 'S')
          ? result = 'Y'
          : result = 'N';
    } catch (err) {
      print(err);
    }
    if (result == 'Y') {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> cancelFCM() async {
    String server = Provider.of<Data>(context, listen: false).server;
    String user = Provider.of<Data>(context, listen: false).user;
    String pass = Provider.of<Data>(context, listen: false).pass;
    String result = '';
    String uri = "https://web.onlinetraq.com/module/APIv1/005-3.php";
    var jsonData = json.encode({
      "server": server,
      "user": user,
      "pass": pass,
    });
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
      print(response.data);
      Map<String, dynamic> data = json.decode(response.data);
      (statusCode == 200) && (data['result'] == 'S')
          ? result = 'Y'
          : result = 'N';
    } catch (err) {
      print(err);
    }
    if (result == 'Y') {
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Provider.of<Data>(context, listen: false).changeFocus(false);
        Provider.of<Data>(context, listen: false).changeFocusVehicles('');
        return true;
      },
      child: Scaffold(
        backgroundColor: Color.fromRGBO(247, 247, 247, 1),
        appBar: AppBar(
          title: Text('Tool'),
        ),
        body: Container(
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height / 17,
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0, right: 12),
                        child: Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Push event notification',
                                  style: TextStyle(
                                      fontFamily: 'Arial', fontSize: 22),
                                  maxLines: 2,
                                ),
                              ),
                              FutureBuilder<bool>(
                                  future: isShareNotificationOn(),
                                  builder: (context, isNotificationOn) {
                                    if (isNotificationOn.hasData) {
                                      Provider.of<Data>(context, listen: false)
                                          .changePushSwitch(
                                              isNotificationOn.data);
                                    }
                                    return CupertinoSwitch(
                                        value: Provider.of<Data>(context)
                                            .pushNotSwitch,
                                        onChanged: (newValue) async {
                                          showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (context) =>
                                                  WillPopScope(
                                                      onWillPop: () =>
                                                          Future.value(false),
                                                      child:
                                                          CupertinoActivityIndicator(
                                                        radius: 20,
                                                        animating: true,
                                                      )));
                                          Provider.of<Data>(context,
                                                  listen: false)
                                              .changePushSwitch(newValue);
                                          await changeShareNotification(
                                                  newValue: newValue)
                                              .then((value) async {
                                            if (newValue) {
                                              await updateFCMToken();
                                            } else {
                                              await cancelFCM();
                                            }
                                            setState(() {
                                              Navigator.of(context).pop();
                                            });
                                          });
                                        });
                                  }),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0, right: 12),
                        child: Container(
                          decoration: BoxDecoration(
                              border: Border(
                                  top: BorderSide(
                                      width: 1, color: Colors.black26))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Event log',
                                  style: TextStyle(
                                      fontFamily: 'Arial', fontSize: 22),
                                ),
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
                                            builder: (context) => EventLog(
                                                jsonData: widget.jsonData)));
                                  }),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0, right: 12),
                        child: Container(
                          decoration: BoxDecoration(
                              border: Border(
                                  top: BorderSide(
                                      width: 1, color: Colors.black26))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Diagnosis & Support',
                                  style: TextStyle(
                                      fontFamily: 'Arial', fontSize: 22),
                                ),
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
                                            builder: (context) =>
                                                SelectVehicleDiagnosis(
                                                    jsonData:
                                                        widget.jsonData)));
                                  }),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0, right: 12),
                        child: Container(
                          decoration: BoxDecoration(
                              border: Border(
                                  top: BorderSide(
                                      width: 1, color: Colors.black26))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Log out',
                                  style: TextStyle(
                                      fontFamily: 'Arial', fontSize: 22),
                                ),
                              ),
                              IconButton(
                                  icon: Icon(
                                    Icons.navigate_next,
                                    size: 40,
                                    color: Colors.black45,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                        context: context,
                                        builder: (BuildContext context) =>
                                            CupertinoAlertDialog(
                                              title: Text(
                                                  "Are you sure to log out?"),
                                              actions: <Widget>[
                                                CupertinoDialogAction(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  isDefaultAction: true,
                                                  child: Text('Cancel'),
                                                ),
                                                CupertinoDialogAction(
                                                  onPressed: () async {
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
                                                    if (Provider.of<Data>(
                                                            context,
                                                            listen: false)
                                                        .pushNotSwitch) {
                                                      await cancelFCM();
                                                    }
                                                    Provider.of<Data>(context,
                                                            listen: false)
                                                        .initAllProperties();
                                                    Navigator.pushAndRemoveUntil(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                LoginPage()),
                                                        (route) => false);
                                                  },
                                                  child: Text("Yes"),
                                                )
                                              ],
                                            ));
                                  }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

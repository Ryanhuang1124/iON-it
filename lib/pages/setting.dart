import 'dart:async';

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
  Future<bool> deleteShared() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return true;
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
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0, right: 12),
                      child: Container(
                        height: 70,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Push event notification',
                              style:
                                  TextStyle(fontFamily: 'Arial', fontSize: 22),
                            ),
                            CupertinoSwitch(
                                value: Provider.of<Data>(context).pushNotSwitch,
                                onChanged: (newValue) {
                                  Provider.of<Data>(context, listen: false)
                                      .changePushSwitch(newValue);
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
                        height: 70,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Event log',
                              style:
                                  TextStyle(fontFamily: 'Arial', fontSize: 22),
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
                        height: 70,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Diagnosis & Support',
                              style:
                                  TextStyle(fontFamily: 'Arial', fontSize: 22),
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
                        height: 70,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Log out',
                              style:
                                  TextStyle(fontFamily: 'Arial', fontSize: 22),
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
                                                      barrierDismissible: false,
                                                      builder: (context) =>
                                                          WillPopScope(
                                                              onWillPop: () =>
                                                                  Future.value(
                                                                      false),
                                                              child:
                                                                  CupertinoActivityIndicator(
                                                                radius: 20,
                                                                animating: true,
                                                              )));
                                                  bool result = await deleteShared()
                                                      .whenComplete(() =>
                                                          Navigator.of(context,
                                                                  rootNavigator:
                                                                      true)
                                                              .pop());
                                                  if (result) {
                                                    Navigator.of(context)
                                                        .pushNamedAndRemoveUntil(
                                                            '/login',
                                                            (Route<dynamic>
                                                                    route) =>
                                                                false);
                                                  }
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
              )
            ],
          ),
        ),
      ),
    );
  }
}

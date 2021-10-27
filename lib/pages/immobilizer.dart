import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ion_it/main.dart';

class SMSData {
  String name;
  String phone;
  String imei;
}

class Immobilizer extends StatefulWidget {
  final String jsonData;

  const Immobilizer({Key key, @required this.jsonData}) : super(key: key);
  @override
  _ImmobilizerState createState() => _ImmobilizerState();
}

class _ImmobilizerState extends State<Immobilizer> {
  List<SMSData> smsDataList = [];

  void _sendSMS(String message, List<String> recipents) async {
    String _result = await sendSMS(message: message, recipients: recipents)
        .catchError((onError) {
      print(onError);
    });
    print(_result);
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

    return allVehiclesData;
  }

  String generateRandomString(int len) {
    var r = Random();
    const _chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    return List.generate(len, (index) => _chars[r.nextInt(_chars.length)])
        .join();
  }

  String encodeSMS() {
    String lastTwo = DateFormat('dd').format(DateTime.now());
    String name = Provider.of<Data>(context, listen: false).immoVehicle;
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

  _textMeImmo(int type) async {
    String name = Provider.of<Data>(context, listen: false).immoVehicle;
    String phone;
    String apeN = encodeSMS();
    var uri;
    for (var item in smsDataList) {
      if (item.name == name) {
        phone = item.phone;
      }
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

  Future<bool> uploadImmobilizerState(int id, bool switcher) async {
    String server = Provider.of<Data>(context, listen: false).server;
    String user = Provider.of<Data>(context, listen: false).user;
    String pass = Provider.of<Data>(context, listen: false).pass;

    DateTime now = new DateTime.now();
    String date = new DateTime(
            now.year, now.month, now.day, now.hour, now.minute, now.second)
        .toString()
        .split('.')[0];
    String status;
    switcher ? status = "O" : status = "F";

    String uri = "https://web.onlinetraq.com/module/APIv1/004-1.php";

    var jsonData = json.encode({
      "server": server,
      "user": user,
      "pass": pass,
      "deviceID": id,
      "status": status,
      "sDate": date.toString()
    });
    FormData formData = FormData.fromMap({'data': jsonData});

    var response = await Dio().post(uri, data: formData);
    Map<String, dynamic> data = json.decode(response.data);

    if (data['result'] == "S" && data['status'] == "Y")
      return true;
    else
      return false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<dynamic, List>>(
        future: getVehicles(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var id, name;
            name = Provider.of<Data>(context, listen: false).immoVehicle;
            snapshot.data.forEach((key, value) {
              if (value[0] == name) {
                id = key;
              }
            });
            if (Provider.of<Data>(context, listen: false)
                    .immobilizerSwitch[name] ==
                null) {
              Provider.of<Data>(context, listen: false)
                  .immobilizerSwitch[name] = false;
            }

            return WillPopScope(
              onWillPop: () async {
                Provider.of<Data>(context, listen: false).changeFocus(false);
                Provider.of<Data>(context, listen: false)
                    .changeFocusVehicles('');
                return true;
              },
              child: Scaffold(
                backgroundColor: Color.fromRGBO(247, 247, 247, 1),
                appBar: AppBar(
                  title: Text('Immobilizer'),
                ),
                body: Container(
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 17,
                      ),
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Container(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: ElevatedButton(
                                            onPressed: () async {
                                              showDialog(
                                                  context: context,
                                                  builder: (BuildContext
                                                          context) =>
                                                      CupertinoAlertDialog(
                                                        title: Text(
                                                            "No bluetooth devices available!use text message instead?The average waiting time delivering text message is 2 to 3 minutes"),
                                                        actions: <Widget>[
                                                          CupertinoDialogAction(
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                            },
                                                            isDefaultAction:
                                                                true,
                                                            child:
                                                                Text('Cancel'),
                                                          ),
                                                          CupertinoDialogAction(
                                                            onPressed:
                                                                () async {
                                                              int iD_int =
                                                                  int.parse(id);
                                                              showDialog(
                                                                  context:
                                                                      context,
                                                                  barrierDismissible:
                                                                      false,
                                                                  builder:
                                                                      (context) =>
                                                                          WillPopScope(
                                                                            onWillPop: () =>
                                                                                Future.value(false),
                                                                            child:
                                                                                CupertinoActivityIndicator(
                                                                              radius: 20,
                                                                              animating: true,
                                                                            ),
                                                                          ));
                                                              bool data = await uploadImmobilizerState(
                                                                      iD_int,
                                                                      false)
                                                                  .whenComplete(() => Navigator.of(
                                                                          context,
                                                                          rootNavigator:
                                                                              true)
                                                                      .pop());
                                                              Provider.of<Data>(
                                                                      context,
                                                                      listen:
                                                                          false)
                                                                  .changeImmoSwitch(
                                                                      name,
                                                                      false);
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                              _textMeImmo(3);
                                                            },
                                                            child: Text("ok"),
                                                          )
                                                        ],
                                                      ));
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                'Deactivate',
                                                style: TextStyle(fontSize: 20),
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
                                                  builder: (BuildContext
                                                          context) =>
                                                      CupertinoAlertDialog(
                                                        title: Text(
                                                            "No bluetooth devices available!use text message instead?The average waiting time delivering text message is 2 to 3 minutes"),
                                                        actions: <Widget>[
                                                          CupertinoDialogAction(
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                            },
                                                            isDefaultAction:
                                                                true,
                                                            child:
                                                                Text('Cancel'),
                                                          ),
                                                          CupertinoDialogAction(
                                                            onPressed:
                                                                () async {
                                                              int iD_int =
                                                                  int.parse(id);
                                                              showDialog(
                                                                  context:
                                                                      context,
                                                                  barrierDismissible:
                                                                      false,
                                                                  builder:
                                                                      (context) =>
                                                                          WillPopScope(
                                                                            onWillPop: () =>
                                                                                Future.value(false),
                                                                            child:
                                                                                CupertinoActivityIndicator(
                                                                              radius: 20,
                                                                              animating: true,
                                                                            ),
                                                                          ));
                                                              bool data = await uploadImmobilizerState(
                                                                      iD_int,
                                                                      false)
                                                                  .whenComplete(() => Navigator.of(
                                                                          context,
                                                                          rootNavigator:
                                                                              true)
                                                                      .pop());
                                                              Provider.of<Data>(
                                                                      context,
                                                                      listen:
                                                                          false)
                                                                  .changeImmoSwitch(
                                                                      name,
                                                                      false);
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                              _textMeImmo(2);
                                                            },
                                                            child: Text("ok"),
                                                          )
                                                        ],
                                                      ));
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                'Active',
                                                style: TextStyle(fontSize: 20),
                                              ),
                                            )),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          } else {
            return Scaffold(
                body: Center(
                    child: CupertinoActivityIndicator(
              radius: 20,
            )));
          }
        });
  }
}

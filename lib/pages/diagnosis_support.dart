import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ion_it/main.dart';
import 'package:provider/provider.dart';

class DiagnosisPage extends StatefulWidget {
  final String jsonData;
  const DiagnosisPage({Key key, @required this.jsonData}) : super(key: key);

  @override
  _DiagnosisPageState createState() => _DiagnosisPageState();
}

class _DiagnosisPageState extends State<DiagnosisPage> {
  final TextEditingController textController = TextEditingController();

  Future<String> postDiagnosisApi() async {
    String server = Provider.of<Data>(context, listen: false).server;
    String user = Provider.of<Data>(context, listen: false).user;
    String pass = Provider.of<Data>(context, listen: false).pass;
    String id = Provider.of<Data>(context, listen: false).diagnosisId;
    String description = textController.text;

    bool result = false;
    String uri = "https://web.onlinetraq.com/module/APIv1/004-2.php";
    var jsonData = json.encode({
      "server": server,
      "user": user,
      "pass": pass,
      "deviceID": int.parse(id),
      "deviceLog": "GPRS N",
      "userP": description
    });
    FormData formData = FormData.fromMap({'data': jsonData});

    var response = await Dio().post(uri, data: formData);
    Map<String, dynamic> data = json.decode(response.data);

    // (response.statusCode==200) && (data['result']== 'S')?result=true:result=false;
    //
    // if(result){
    // }
    if (data['result'] == 'S') {
      return data['status'];
    } else {
      return data['result'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
          ),
        ],
        title: Center(
            child: Text(
          'Diagnosis ＆ Support',
          style: TextStyle(fontSize: 26, fontFamily: 'Arial'),
        )),
      ),
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height / 30,
          ),
          Container(
            height: MediaQuery.of(context).size.height / 16,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 12),
                  child: Text(
                    'Problem   Description',
                    style: TextStyle(fontFamily: 'Arial', fontSize: 22),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 66),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
              ),
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.3,
              child: TextFormField(
                style: TextStyle(fontSize: 20, color: Colors.black),
                keyboardType: TextInputType.multiline,
                maxLines: 12,
                controller: textController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: BorderSide(width: 1, color: Colors.black38),
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
              onTap: () async {
                postDiagnosisApi();
                showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => WillPopScope(
                        onWillPop: () => Future.value(false),
                        child: CupertinoActivityIndicator(
                          radius: 20,
                          animating: true,
                        )));
                String result = await postDiagnosisApi().whenComplete(
                    () => Navigator.of(context, rootNavigator: true).pop());
                if (result == 'Y') {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) => CupertinoAlertDialog(
                            title: Text("Upload Success."),
                            actions: <Widget>[
                              CupertinoDialogAction(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text("OK"),
                              )
                            ],
                          ));
                } else {
                  if (result == 'R') {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) => CupertinoAlertDialog(
                              title: Text("Upload repeatedly."),
                              actions: <Widget>[
                                CupertinoDialogAction(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text("OK"),
                                )
                              ],
                            ));
                  } else {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) => CupertinoAlertDialog(
                              title: Text("Upload Failed."),
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
              child: SvgPicture.asset(
                'assets/svg/confirm.svg',
                height: 60,
              )),
        ],
      ),
    );
  }
}

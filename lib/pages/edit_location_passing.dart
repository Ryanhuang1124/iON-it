import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ion_it/main.dart';
import 'package:provider/provider.dart';

class EditLocationPassing extends StatefulWidget {
  final String jsonData;

  const EditLocationPassing({Key key, @required this.jsonData})
      : super(key: key);
  @override
  _EditLocationPassingState createState() => _EditLocationPassingState();
}

class _EditLocationPassingState extends State<EditLocationPassing> {
  BitmapDescriptor customMarker;
  GoogleMapController _mapController;
  Map<String, Marker> point = {};
  Map<String, Circle> round = {};

  var textController = TextEditingController();

  Future<bool> getAddress(String address) async {
    String uri = "https://web.onlinetraq.com/module/APIv1/006-2.php";
    var data = json.decode(widget.jsonData);
    var jsonData = json.encode({
      "server": data['server'],
      "user": data['user'],
      "pass": data['pass'],
      "add": address
    });
    FormData formData = FormData.fromMap({'data': jsonData});
    var response = await Dio().post(uri, data: formData);
    Map<String, dynamic> finalData = json.decode(response.data);

    if (finalData['status'] == 'S' && response.statusCode == 200) {
      LatLng position = LatLng(
          double.parse(finalData['lat']), double.parse(finalData['lng']));
      Provider.of<Data>(context, listen: false).changePassingPosition(position);

      return true;
    } else {
      return false;
    }
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
        bottomSheet: Container(
          padding: EdgeInsets.only(left: 16, right: 16),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20))),
          height: MediaQuery.of(context).size.height / 10,
          child: Column(
            children: [
              Expanded(
                  flex: 1,
                  child: Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            try {
                              showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => WillPopScope(
                                      onWillPop: () => Future.value(false),
                                      child: CupertinoActivityIndicator(
                                        radius: 20,
                                        animating: true,
                                      )));
                              textController.text.isEmpty
                                  ? throw ('Empty')
                                  : print('Correct');
                              if (textController.text.isNotEmpty) {
                                bool result =
                                    await getAddress(textController.text)
                                        .whenComplete(() => Navigator.of(
                                                context,
                                                rootNavigator: true)
                                            .pop());
                                result
                                    ? Navigator.pop(
                                        context,
                                      )
                                    : throw ("Wrong address");
                              }
                            } catch (error) {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) =>
                                      CupertinoAlertDialog(
                                        title: Text("Error: $error "),
                                        actions: <Widget>[
                                          CupertinoDialogAction(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text("Try Again"),
                                          )
                                        ],
                                      ));
                            }
                          },
                          child: Container(
                            child: SvgPicture.asset(
                              'assets/svg/confirm.svg',
                              height: MediaQuery.of(context).size.height / 15,
                            ),
                          ),
                        )
                      ],
                    ),
                  )),
            ],
          ),
        ),
        body: Container(
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.02,
                ),
                Text(
                  'Enter Address :',
                  style: TextStyle(fontFamily: 'Arial', fontSize: 22),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.05,
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  height: MediaQuery.of(context).size.height * 0.2,
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
              ],
            ),
          ),
        ));
  }
}

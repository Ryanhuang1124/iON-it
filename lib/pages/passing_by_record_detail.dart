import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:ion_it/main.dart';
import 'package:provider/provider.dart';

class DataObj {
  String id;
  String st;
  String location;
  String ed;
  String max;
  String address;
}

class PassingByRecordDetail extends StatefulWidget {
  final String jsonData;

  const PassingByRecordDetail({Key key, @required this.jsonData})
      : super(key: key);
  @override
  _PassingByRecordDetailState createState() => _PassingByRecordDetailState();
}

class _PassingByRecordDetailState extends State<PassingByRecordDetail> {
  Future<String> getAddress(String lat, String lng) async {
    String uri = "https://web.onlinetraq.com/module/APIv1/006-1.php";
    var data = json.decode(widget.jsonData);
    var jsonData = json.encode({
      "server": data['server'],
      "user": data['user'],
      "pass": data['pass'],
      "lat": lat,
      "lng": lng,
      "lang": "en"
    });
    FormData formData = FormData.fromMap({'data': jsonData});
    var response = await Dio().post(uri, data: formData);
    Map<String, dynamic> finalData = json.decode(response.data);

    if (finalData['status'] == 'S' && response.statusCode == 200) {
      return finalData['data'];
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

  Future<List<DataObj>> getPassingData(List<dynamic> idList) async {
    String server = Provider.of<Data>(context, listen: false).server;
    String user = Provider.of<Data>(context, listen: false).user;
    String pass = Provider.of<Data>(context, listen: false).pass;
    DateTime date = Provider.of<Data>(context, listen: false).passingDate;
    LatLng position = Provider.of<Data>(context).passingPosition;
    double radius = Provider.of<Data>(context).passingRadius;
    String sDate = DateFormat('yyyy-MM-dd').format(date);
    String uri = "https://web.onlinetraq.com/module/APIv1/003-4.php";

    List<DataObj> dataList = [];

    for (var item_out in idList) {
      var jsonData = json.encode({
        "server": server,
        "user": user,
        "pass": pass,
        "deviceID": item_out,
        "setDate": sDate,
        "lat": position.latitude.toString(),
        "lng": position.longitude.toString(),
        "range": radius.toString(),
        "unit": "K",
      });
      FormData formData = FormData.fromMap({'data': jsonData});
      var response = await Dio().post(uri, data: formData);
      Map<String, dynamic> data = json.decode(response.data);

      if (response.statusCode == 200 &&
          data['status'] == 'Y' &&
          data['data'].isNotEmpty) {
        DataObj obj = new DataObj();
        obj.id = item_out;
        for (var item in data['data']) {
          obj.st = item['st'];
          obj.ed = item['ed'];
          obj.location = item['location'];
          obj.max = item['max'].toString();
        }
        if (obj.location != null) {
          List<String> location = obj.location.split(',');
          String address = await getAddress(location[0], location[1]);
          obj.address = address;
        }
        dataList.add(obj);
      }
    }
    return dataList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
            child: Text(
          'Passing-by Record',
          style: TextStyle(fontSize: 26, fontFamily: 'Arial'),
        )),
      ),
      body: FutureBuilder<Map<dynamic, List>>(
          future: getVehicles(),
          builder: (context, snapshot) {
            List<dynamic> idList = [];
            if (snapshot.hasData) {
              snapshot.data.forEach((key, value) {
                idList.add(key);
              });
              return FutureBuilder<List<DataObj>>(
                  future: getPassingData(idList),
                  builder: (context, snap) {
                    if (snap.hasData) {
                      return Container(
                        child: ListView.builder(
                            itemCount: snap.data.length,
                            itemBuilder: (ctx, i) {
                              return Visibility(
                                visible:
                                    snap.data[i].address == null ? false : true,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 12.0),
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 12.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                              width: 1, color: Colors.black26),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            snapshot.data[snap.data[i].id][0],
                                            style: TextStyle(
                                                fontFamily: 'Arial',
                                                fontSize: 22),
                                          ),
                                          Text(
                                            '${snap.data[i].st == null ? 'No data' : snap.data[i].st} ~ ${snap.data[i].ed == null ? 'No data' : snap.data[i].ed}',
                                            style: TextStyle(
                                                fontFamily: 'Arial',
                                                fontSize: 22),
                                          ),
                                          Text(
                                            'Max.speed: ${snap.data[i].max == null ? 'No data' : int.parse(snap.data[i].max) / 1000}  km/h',
                                            style: TextStyle(
                                                fontFamily: 'Arial',
                                                fontSize: 22),
                                          ),
                                          Text(
                                            'Entering from:',
                                            style: TextStyle(
                                                fontFamily: 'Arial',
                                                fontSize: 22),
                                          ),
                                          Text(
                                            snap.data[i].address == null
                                                ? 'No data'
                                                : snap.data[i].address,
                                            style: TextStyle(
                                                fontFamily: 'Arial',
                                                fontSize: 22),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                      );
                    } else {
                      return Center(
                          child: CupertinoActivityIndicator(
                        radius: 20,
                      ));
                    }
                  });
            } else {
              return Center(
                  child: CupertinoActivityIndicator(
                radius: 20,
              ));
            }
          }),
    );
  }
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ion_it/main.dart';
import 'package:ion_it/widgets/customInfoWidget.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;

class PointObject {
  String name;
  LatLng location;
}

class MarkerData {
  BitmapDescriptor descriptor;
  String id;
  List value = [];
  String address;
}

class SelectVehicleHome extends StatefulWidget {
  final String jsonData;
  const SelectVehicleHome({Key key, @required this.jsonData}) : super(key: key);

  @override
  _SelectVehicleHomeState createState() => _SelectVehicleHomeState();
}

class _SelectVehicleHomeState extends State<SelectVehicleHome> {
  Future<String> getImageID(String deviceID) async {
    String imageID;

    String uri = "https://web.onlinetraq.com/module/APIv1/003-1.php";
    FormData formData = FormData.fromMap({'data': widget.jsonData});
    var response = await Dio().post(uri, data: formData);
    Map<String, dynamic> data = json.decode(response.data);

    for (var item in data['data']) {
      if (item['id'] == deviceID) {
        imageID = item['icon'];
      }
    }
    if (imageID.isEmpty) {
      imageID = '151';
    }
    return imageID;
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

  void removeMarker(String key) {
    Provider.of<Data>(context, listen: false).descriptors.remove(key);
    Provider.of<Data>(context, listen: false).markers.remove(key);
  }

  Future<String> getAddress(LatLng point) async {
    String uri = "https://web.onlinetraq.com/module/APIv1/006-1.php";
    var data = json.decode(widget.jsonData);
    var jsonData = json.encode({
      "server": data['server'],
      "user": data['user'],
      "pass": data['pass'],
      "lat": point.latitude,
      "lng": point.longitude,
      "lang": "zh-TW"
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

  void makeMarker(String key, List value) async {
    //get address by LatLng
    List<String> latlng = value[1].split(',');
    var point = LatLng(double.parse(latlng[0]), double.parse(latlng[1]));
    var address = await getAddress(point);

    //get network image
    String imageID = await getImageID(key);
    var imageUrl = Uri.parse(
        "https://web.onlinetraq.com/template/default/img/car/car_$imageID.png");
    http.Response response = await http.get(imageUrl);
    if (response.statusCode != 200) {
      imageUrl = Uri.parse(
          "https://web.onlinetraq.com/template/default/img/car/car_151.png");
      response = await http.get(imageUrl);
    }
    var originalUnit8List = response.bodyBytes;

    //resize and transform
    var codec = await ui.instantiateImageCodec(originalUnit8List,
        targetHeight: 120, targetWidth: 120);
    var frameInfo = await codec.getNextFrame();
    ui.Image targetUiImage = frameInfo.image;
    ByteData targetByteData =
        await targetUiImage.toByteData(format: ui.ImageByteFormat.png);
    var targetlUinit8List = targetByteData.buffer.asUint8List();

    //make a marker
    BitmapDescriptor customMarker =
        BitmapDescriptor.fromBytes(targetlUinit8List);
    MarkerData obj = new MarkerData();
    obj.descriptor = customMarker;
    obj.id = key;
    obj.value = value;
    obj.address = address;
    Provider.of<Data>(context, listen: false).descriptors[key] = obj;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<dynamic, List>>(
        future: getVehicles(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<String> idList = [];
            Map<String, dynamic> idMap = {};
            //idMap=={"name":id}
            if (Provider.of<Data>(context, listen: false)
                .homeVehicleSelect
                .isEmpty) {
              Map<String, bool> vehicles = {};
              snapshot.data.forEach((key, value) {
                vehicles[value[0]] = false;
              });
              Provider.of<Data>(context, listen: false).homeVehicleSelect =
                  vehicles;
            }
            snapshot.data.forEach((key, value) {
              idList.add(key);
            });
            snapshot.data.forEach((key, value) {
              idMap[value[0]] = key;
            });

            return WillPopScope(
              onWillPop: () async {
                showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => WillPopScope(
                        onWillPop: () => Future.value(false),
                        child: CupertinoActivityIndicator(
                          radius: 20,
                          animating: true,
                        )));

                Provider.of<Data>(context, listen: false).changeFocus(false);
                Provider.of<Data>(context, listen: false)
                    .changeFocusVehicles('');
                for (var item in Provider.of<Data>(context, listen: false)
                    .homeVehicleSelect
                    .entries) {
                  if (item.value) {
                    await makeMarker(
                        idMap[item.key], snapshot.data[idMap[item.key]]);
                  }
                  if (!item.value) {
                    removeMarker(idMap[item.key]);
                  }
                }
                Navigator.of(context, rootNavigator: true).pop();
                return true;
              },
              child: Scaffold(
                appBar: AppBar(
                  title: Center(
                      child: Text(
                    'Select  Vehicle',
                    style: TextStyle(fontSize: 26, fontFamily: 'Arial'),
                  )),
                ),
                body: Container(
                  padding: EdgeInsets.only(left: 12, right: 12),
                  child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: snapshot.data.length,
                      itemBuilder: (ctx, i) => GestureDetector(
                          onTap: () {
                            Map newValue =
                                Provider.of<Data>(context, listen: false)
                                    .homeVehicleSelect;
                            newValue[snapshot.data[idList[i]][0]] =
                                !newValue[snapshot.data[idList[i]][0]];
                            Provider.of<Data>(context, listen: false)
                                .changeHomeVehicles(newValue);
                          },
                          child: Container(
                            constraints: BoxConstraints(
                                minHeight:
                                    MediaQuery.of(context).size.height * 0.055),
                            decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        width: 1, color: Colors.black26))),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: Container(
                                    child: Text(
                                      snapshot.data[idList[i]][0],
                                      style: TextStyle(
                                          fontFamily: 'Arial', fontSize: 22),
                                      maxLines: 5,
                                      softWrap: true,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Visibility(
                                      visible: Provider.of<Data>(context)
                                              .homeVehicleSelect[
                                          snapshot.data[idList[i]][0]],
                                      child: SvgPicture.asset(
                                        'assets/svg/yes.svg',
                                        height: 20,
                                        color: Colors.indigo,
                                      )),
                                ),
                              ],
                            ),
                          ))),
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

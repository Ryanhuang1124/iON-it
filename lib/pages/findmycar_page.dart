import 'dart:convert';
import 'package:ion_it/main.dart';
import 'package:ion_it/pages/findmycar_detail.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:ion_it/pages/home_page.dart';
import 'package:flutter/material.dart';

class FindMyCar extends StatefulWidget {
  final String jsonData;

  const FindMyCar({Key key, @required this.jsonData}) : super(key: key);
  @override
  _FindMyCarState createState() => _FindMyCarState();
}

class _FindMyCarState extends State<FindMyCar> {
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

  Future<void> _launchUniversalLinkIos(String url) async {
    if (await canLaunch(url)) {
      final bool nativeAppLaunchSucceeded = await launch(
        url,
        forceSafariVC: false,
        universalLinksOnly: true,
      );
      if (!nativeAppLaunchSucceeded) {
        await launch(
          url,
          forceSafariVC: true,
        );
      }
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
        appBar: AppBar(
          title: Center(
              child: Text(
            'Select  Vehicle',
            style: TextStyle(fontSize: 26, fontFamily: 'Arial'),
          )),
        ),
        body: Container(
            padding: EdgeInsets.only(left: 12, right: 12),
            child: FutureBuilder<Map<dynamic, List>>(
                future: getVehicles(),
                builder: (context, snapshot) {
                  List<String> idList = [];
                  if (snapshot.hasData) {
                    snapshot.data.forEach((key, value) {
                      idList.add(key);
                    });
                    return ListView.builder(
                        shrinkWrap: true,
                        itemCount: snapshot.data.length,
                        itemBuilder: (ctx, i) => GestureDetector(
                            onTap: () {
                              //snapshot.data[idList[i]][1] =destination
                              List<String> destination =
                                  snapshot.data[idList[i]][1].split(',');
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => FindMyCarDetail(
                                            destination: destination,
                                          ))).then((value) {
                                //call back here
                              });
                              //
                              // String navigateUrl =
                              //     'https://www.google.com/maps/dir/?api=1&destination=' +
                              //         snapshot.data[idList[i]][1] +
                              //         "&travelmode=driving";
                            },
                            child: Container(
                              constraints: BoxConstraints(
                                  minHeight:
                                      MediaQuery.of(context).size.height *
                                          0.055),
                              decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                          width: 1, color: Colors.black26))),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
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
                                ],
                              ),
                            )));
                  } else {
                    return Container(
                        child: Center(
                            child: CupertinoActivityIndicator(
                                radius: 20, animating: true)));
                  }
                })),
      ),
    );
  }
}

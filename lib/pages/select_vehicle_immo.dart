import 'dart:convert';
import 'package:flutter_svg/svg.dart';
import 'package:ion_it/main.dart';
import 'package:ion_it/pages/immobilizer.dart';
import 'package:ion_it/pages/smartfence_page.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:ion_it/pages/home_page.dart';
import 'package:flutter/material.dart';

class SelectVehicleImmo extends StatefulWidget {
  final String jsonData;

  const SelectVehicleImmo({Key key, @required this.jsonData}) : super(key: key);
  @override
  _SelectVehicleImmoState createState() => _SelectVehicleImmoState();
}

class _SelectVehicleImmoState extends State<SelectVehicleImmo> {
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
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                  onTap: () {
                    if (Provider.of<Data>(context, listen: false).immoVehicle !=
                        null) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  Immobilizer(jsonData: widget.jsonData)));
                    }
                  },
                  child: Container(
                      child: SvgPicture.asset(
                    'assets/svg/next.svg',
                    height: 30,
                    color: Colors.white,
                  ))),
            )
          ],
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
                              Provider.of<Data>(context, listen: false)
                                  .changeImmoVehicle(
                                      snapshot.data[idList[i]][0]);
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
                                                .immoVehicle ==
                                            (snapshot.data[idList[i]][0]),
                                        child: SvgPicture.asset(
                                          'assets/svg/yes.svg',
                                          height: 20,
                                          color: Colors.indigo,
                                        )),
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

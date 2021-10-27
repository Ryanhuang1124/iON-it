import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ion_it/pages/history_detail_page.dart';
import 'package:provider/provider.dart';
import 'package:ion_it/main.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:intl/intl.dart';

class History extends StatefulWidget {
  final String jsonData;

  const History({Key key, @required this.jsonData}) : super(key: key);
  @override
  _HistoryState createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  Future<BitmapDescriptor> customMarker;

  Future<BitmapDescriptor> getMarkerIconFromAsset(String path) async {
    var result;
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: 90);
    ui.FrameInfo fi = await codec.getNextFrame();
    result = (await fi.image.toByteData(format: ui.ImageByteFormat.png))
        .buffer
        .asUint8List();
    BitmapDescriptor.fromBytes(result);
    return BitmapDescriptor.fromBytes(result);
  }

  @override
  void initState() {
    super.initState();
    customMarker = getMarkerIconFromAsset('assets/images/marker.png');
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
            )
          ],
          title: Center(
              child: Text(
            'History',
            style: TextStyle(fontSize: 26, fontFamily: 'Arial'),
          )),
        ),
        body: Container(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12),
                child: Container(
                  decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(width: 1, color: Colors.black26))),
                  height: MediaQuery.of(context).size.height / 14,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Vehicle',
                        style: TextStyle(fontSize: 20, fontFamily: 'Arial'),
                      ),
                      Text(
                        Provider.of<Data>(context).historyVehicle,
                        style: TextStyle(fontSize: 20, fontFamily: 'Arial'),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12),
                child: GestureDetector(
                  onTap: () {
                    DatePicker.showDatePicker(context, onConfirm: (date) {
                      Provider.of<Data>(context, listen: false)
                          .changeHistoryDate(date);
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        border: Border(
                            bottom:
                                BorderSide(width: 1, color: Colors.black26))),
                    height: MediaQuery.of(context).size.height / 14,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Date',
                          style: TextStyle(fontSize: 20, fontFamily: 'Arial'),
                        ),
                        Container(
                            child: Text(
                          DateFormat("yyyy-MM-dd")
                              .format(Provider.of<Data>(context).historyDate),
                          style: TextStyle(fontSize: 20, fontFamily: 'Arial'),
                        )),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12),
                child: GestureDetector(
                  onTap: () {
                    DatePicker.showTime12hPicker(context, onConfirm: (date) {
                      Provider.of<Data>(context, listen: false)
                          .changeHistoryStTime(date);
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        border: Border(
                            bottom:
                                BorderSide(width: 1, color: Colors.black26))),
                    height: MediaQuery.of(context).size.height / 14,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Start',
                          style: TextStyle(fontSize: 20, fontFamily: 'Arial'),
                        ),
                        Container(
                            child: Text(
                          DateFormat("HH:mm")
                              .format(Provider.of<Data>(context).historyStTime),
                          style: TextStyle(fontSize: 20, fontFamily: 'Arial'),
                        )),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12),
                child: GestureDetector(
                  onTap: () {
                    DatePicker.showTime12hPicker(context, onConfirm: (date) {
                      Provider.of<Data>(context, listen: false)
                          .changeHistoryEdTime(date);
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        border: Border(
                            bottom:
                                BorderSide(width: 1, color: Colors.black26))),
                    height: MediaQuery.of(context).size.height / 14,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'End',
                          style: TextStyle(fontSize: 20, fontFamily: 'Arial'),
                        ),
                        Container(
                            child: Text(
                          DateFormat("HH:mm")
                              .format(Provider.of<Data>(context).historyEdTime),
                          style: TextStyle(fontSize: 20, fontFamily: 'Arial'),
                        )),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height / 3,
              ),
              FutureBuilder(
                  future: customMarker,
                  builder: (context, customMarker) {
                    if (customMarker.hasData) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 12, right: 12),
                        child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => HistoryDetail(
                                          jsonData: widget.jsonData,
                                          customIcon: customMarker.data)));
                            },
                            child: Container(
                              child: Center(
                                  child: Text(
                                'Search',
                                style: TextStyle(
                                    fontSize: 22,
                                    color: Colors.white,
                                    fontFamily: 'Arial'),
                              )),
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.height / 14,
                              decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(30)),
                            )),
                      );
                    } else {
                      return Container(
                          child: Center(
                              child: CupertinoActivityIndicator(
                                  radius: 20, animating: true)));
                    }
                  })
            ],
          ),
        ),
      ),
    );
  }
}

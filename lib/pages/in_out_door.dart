import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:ion_it/main.dart';

class Position {
  var latitude;
  var longitude;
}

class InOutDoor extends StatefulWidget {
  @override
  _InOutDoorState createState() => _InOutDoorState();
}

class _InOutDoorState extends State<InOutDoor> {
  Future<Position> _determinePosition() async {
    Location location = new Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    // _serviceEnabled = await location.serviceEnabled();
    // _permissionGranted = await location.hasPermission();
    //
    // if ((!_serviceEnabled) ||
    //     (_permissionGranted != PermissionStatus.granted)) {
    //   print('000');
    //   // showDialog(
    //   //   context: context,
    //   //   builder: (_) => AlertDialog(
    //   //     title: Text('Location Needed'),
    //   //     content: Text(
    //   //         'Please turn on the location services and allow the location permission.'),
    //   //   ),
    //   //   barrierDismissible: false,
    //   // );
    // }
    //
    // if (!_serviceEnabled) {
    //   _serviceEnabled = await location.requestService();
    //   if (!_serviceEnabled) {
    //     return null;
    //   }
    // }
    //
    // if (_permissionGranted == PermissionStatus.denied) {
    //   _permissionGranted = await location.requestPermission();
    //   if (_permissionGranted != PermissionStatus.granted) {
    //     return null;
    //   }
    // }
    Position position = new Position();
    _locationData = await location.getLocation();

    position.latitude = _locationData.latitude;
    position.longitude = _locationData.longitude;
    print(position.latitude);

    // return position;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(247, 247, 247, 1),
      appBar: AppBar(
        title: Text('Radius'),
        actions: [
          IconButton(
            onPressed: () async {
              await _determinePosition();
            },
            icon: Icon(Icons.my_location),
          )
        ],
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
                    padding: const EdgeInsets.only(left: 12.0),
                    child: Container(
                      height: 50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'The vehicle is indoor',
                            style: TextStyle(fontFamily: 'Arial', fontSize: 22),
                          ),
                          CupertinoSwitch(
                              value:
                                  Provider.of<Data>(context).smartFenceIndoor,
                              onChanged: (newValue) {
                                Provider.of<Data>(context, listen: false)
                                    .changeSmartFenceIndoor(newValue);
                              })
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
    );
  }
}

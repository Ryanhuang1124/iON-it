import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ion_it/pages/home_page.dart';
import 'package:ion_it/pages/login_page.dart';
import 'package:ion_it/pages/select_vehicle_home.dart';
import 'package:ion_it/pages/smartfence_page.dart';
import 'package:ion_it/widgets/customInfoWidget.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(Ion_it());
}

class Data extends ChangeNotifier {
  String server;
  String user;
  String pass;
  bool allCheckedValue = false;
  List<bool> checkBoxValue = [];
  double smartFenceRadius = 150;
  LatLng smartFenceMarker;
  String smartFenceVehicle;
  Map<String, SmartFenceData> smartData = <String, SmartFenceData>{};
  bool smartFenceIndoor = false;
  Map<String, bool> immobilizerSwitch = <String, bool>{};
  String immoVehicle;
  String historyVehicle;
  String historyId;
  DateTime historyDate = DateTime.now();
  DateTime historyStTime = DateTime.now();
  DateTime historyEdTime = DateTime.now();
  double passingRadius = 0;
  LatLng passingPosition;
  DateTime passingDate = DateTime.now();
  bool pushNotSwitch = false;
  String eventFilter = 'name';
  String diagnosisVehicle;
  String diagnosisId;
  Map<String, bool> homeVehicleSelect = {};
  GoogleMapController mapController;
  Map<String, MarkerData> descriptors = <String, MarkerData>{};
  Map<String, Marker> markers = <String, Marker>{};
  InfoWidgetRoute infoWidgetRoute;
  bool focus = false;
  String focusVehicleSelect = '';

  void changeAllCheck(bool newValue) {
    this.allCheckedValue = newValue;
  }

  void changeCheckBoxValue(int index, bool newValue) {
    this.checkBoxValue[index] = newValue;
    notifyListeners();
  }

  void changeSmartFenceRadius(double radius) {
    this.smartFenceRadius = radius;
    notifyListeners();
  }

  void changeSmartFenceMarker(LatLng position) {
    this.smartFenceMarker = position;
    notifyListeners();
  }

  void changeSmartFenceVehicle(String name) {
    this.smartFenceVehicle = name;
    notifyListeners();
  }

  void changeSmartFenceIndoor(bool isIndoor) {
    this.smartFenceIndoor = isIndoor;
    notifyListeners();
  }

  void changeLoginData(String server, String user, String pass) {
    this.server = server;
    this.user = user;
    this.pass = pass;
  }

  void changeImmoVehicle(String name) {
    this.immoVehicle = name;
    notifyListeners();
  }

  void changeImmoSwitch(String name, bool newValue) {
    this.immobilizerSwitch[name] = newValue;
    notifyListeners();
  }

  void changeHistoryVehicle(String name, String id) {
    this.historyId = id;
    this.historyVehicle = name;
    notifyListeners();
  }

  void changeHistoryDate(DateTime date) {
    this.historyDate = date;
    notifyListeners();
  }

  void changeHistoryStTime(DateTime date) {
    print(date);
    this.historyStTime = date;
    print(this.historyStTime);
    notifyListeners();
  }

  void changeHistoryEdTime(DateTime date) {
    this.historyEdTime = date;
    notifyListeners();
  }

  void changePassingRadius(double radius) {
    this.passingRadius = radius;
    notifyListeners();
  }

  void changePassingPosition(LatLng position) {
    this.passingPosition = position;
    notifyListeners();
  }

  void changePassingDate(DateTime date) {
    this.passingDate = date;
    notifyListeners();
  }

  void changePushSwitch(bool newValue) {
    this.pushNotSwitch = newValue;
    notifyListeners();
  }

  void changeEventFilter(String filterBy) {
    this.eventFilter = filterBy;
    notifyListeners();
  }

  void changeDiagnosisVehicle(String name, String id) {
    this.diagnosisVehicle = name;
    this.diagnosisId = id;
    notifyListeners();
  }

  void changeHomeVehicles(Map<String, bool> vehicles) {
    this.homeVehicleSelect = vehicles;
    notifyListeners();
  }

  void changeInfoWidgetRoute(InfoWidgetRoute infoWidgetRoute) {
    this.infoWidgetRoute = infoWidgetRoute;
    notifyListeners();
  }

  void changeFocus(bool focus) {
    this.focus = focus;
    notifyListeners();
  }

  void changeFocusVehicles(String vehicle) {
    this.focusVehicleSelect = vehicle;
    notifyListeners();
  }

  void changeSmartFenceData(SmartFenceData obj) {
    this.smartData[obj.smartFenceVehicle] = obj;
    notifyListeners();
  }

  void changeMarker(String id, Marker marker) {
    //use in combineMarker
    this.markers[id] = marker;
    notifyListeners();
  }
}

class Ion_it extends StatefulWidget {
  @override
  _Ion_itState createState() => _Ion_itState();
}

class _Ion_itState extends State<Ion_it> {
  LatLng myLocation;

  Future<List<String>> getSharedAccount() async {
    List<String> accountData;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    accountData = prefs.getStringList('accountData');
    return accountData;
  }


  Future<bool> _checkLocationServiceEnable() async {
    var location = new Location();
    bool _serviceEnabled = false;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
    }
    return _serviceEnabled;
  }

  Future<Position> _determinePosition() async {
    print('into determine position');
    bool serviceEnabled = false;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await _checkLocationServiceEnable();
    if (!serviceEnabled) {
      return null;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      print('Location permissions are denied');
      return null;
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      print(
          'Location permissions are permanently denied, we cannot request permissions.');
      return null;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.

    var position = await Geolocator.getCurrentPosition();

    return position;

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
  }


  @override
  void initState() {
    getSharedAccount();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => Data(),
        child: MaterialApp(
          routes: {
            '/login': (BuildContext context) => LoginPage(),
            '/homepage': (BuildContext context) => HomePage(),
          },
          home: FutureBuilder<List<String>>(
              future: getSharedAccount(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  Provider.of<Data>(context, listen: false).changeLoginData(
                      snapshot.data[0], snapshot.data[1], snapshot.data[2]);
                }

                  return FutureBuilder<Position>(
                    future: _determinePosition(),
                    builder: (context,snapshot) {
                      if(snapshot.connectionState==ConnectionState.done){
                        return LoginPage(position: snapshot.data,);
                      }
                      else{
                        return Scaffold(
                            body: Container(
                                child: Center(
                                    child: CupertinoActivityIndicator(
                                        radius: 20, animating: true))));
                      }
                    }
                  ); //first login

              }),
        ));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ion_it/main.dart';
import 'package:provider/provider.dart';

class SelectVehicleFocus extends StatefulWidget {
  final List<MapEntry> descriptors;

  const SelectVehicleFocus({
    Key key,
    @required this.descriptors,
  }) : super(key: key);

  @override
  _SelectVehicleFocusState createState() => _SelectVehicleFocusState();
}

class _SelectVehicleFocusState extends State<SelectVehicleFocus> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Provider.of<Data>(context, listen: false)
            .focusVehicleSelect
            .isEmpty) {
          Provider.of<Data>(context, listen: false).changeFocus(false);
          Provider.of<Data>(context, listen: false).changeFocusVehicles('');
        } else {
          Provider.of<Data>(context, listen: false).changeFocus(true);
        }
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
              itemCount: widget.descriptors.length,
              itemBuilder: (ctx, i) {
                return GestureDetector(
                    onTap: () {
                      String newValue = widget.descriptors[i].value.value[0];
                      if (Provider.of<Data>(context, listen: false)
                              .focusVehicleSelect !=
                          newValue) {
                        Provider.of<Data>(context, listen: false)
                            .changeFocusVehicles(newValue);
                      } else {
                        Provider.of<Data>(context, listen: false)
                            .changeFocusVehicles('');
                      }
                    },
                    child: Container(
                      constraints: BoxConstraints(
                          minHeight:
                              MediaQuery.of(context).size.height * 0.055),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(width: 1, color: Colors.black26),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 6,
                            child: Container(
                              child: Text(
                                widget.descriptors[i].value.value[0],
                                style: TextStyle(
                                    fontFamily: 'Arial', fontSize: 22),
                                softWrap: true,
                                maxLines: 3,
                              ),
                            ),
                          ),
                          Expanded(
                              flex: 1,
                              child: Visibility(
                                  visible: Provider.of<Data>(context)
                                          .focusVehicleSelect ==
                                      (widget.descriptors[i].value.value[0]),
                                  child: SvgPicture.asset(
                                    'assets/svg/yes.svg',
                                    height: 20,
                                    color: Colors.indigo,
                                  ))),
                        ],
                      ),
                    ));
              }),
        ),
      ),
    );
  }
}

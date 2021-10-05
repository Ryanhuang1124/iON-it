import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:ion_it/main.dart';

class InOutDoor extends StatefulWidget {
  @override
  _InOutDoorState createState() => _InOutDoorState();
}

class _InOutDoorState extends State<InOutDoor> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  Color.fromRGBO(247, 247, 247, 1),
      appBar: AppBar(title: Text('Radius'),),
      body: Container(child: Column(children: [
        SizedBox(height: MediaQuery.of(context).size.height/17,),
        Container(decoration: BoxDecoration(color: Colors.white,),child: Column(children: [
          Padding(
            padding: const EdgeInsets.only(left:12.0),
            child: Container(height: 50,child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('The vehicle is indoor',style: TextStyle(fontFamily: 'Arial',fontSize: 22),),
                CupertinoSwitch(value: Provider.of<Data>(context).smartFenceIndoor, onChanged: (newValue){
                  Provider.of<Data>(context,listen: false).changeSmartFenceIndoor(newValue);
                })
              ],
            ),),
          ),
        ],),)
      ],),),

    );
  }
}


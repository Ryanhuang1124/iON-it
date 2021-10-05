import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ion_it/main.dart';
import 'package:provider/provider.dart';
import 'package:simple_html_css/simple_html_css.dart';


class LogData{
  String name;
  String speed;
  String direction;
  String location;
  String date;
  String event;
}


class EventLog extends StatefulWidget {
  final String jsonData;
  const EventLog({Key key,@required this.jsonData}):super(key:key);
  @override
  _EventLogState createState() => _EventLogState();
}

class _EventLogState extends State<EventLog> {
  String _selection;

  Future<List<dynamic>> getLogData() async{

    String uri="https://web.onlinetraq.com/module/APIv1/005-4.php";
    FormData formData=FormData.fromMap({'data':widget.jsonData});
    var response = await Dio().post(uri,data: formData);
    Map<String,dynamic> data=json.decode(response.data);

    return data['data'];
  }
  Widget openPopMenu() {
    return PopupMenuButton<String>(
        itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
          new PopupMenuItem<String>(
              value: 'name', child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 100,child: Text('Vehicle')),
                  Provider.of<Data>(context,listen: false).eventFilter=='name'?SvgPicture.asset('assets/svg/yes.svg',height: 20,color: Colors.indigo,):Container(),
                ],
              ),),
          new PopupMenuItem<String>(
              value: 'event', child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 100,child: Text('Event')),
              Provider.of<Data>(context,listen: false).eventFilter=='event'?SvgPicture.asset('assets/svg/yes.svg',height: 20,color: Colors.indigo,):Container(),
            ],
          ),),
          new PopupMenuItem<String>(
              value: 'date', child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 100,child: Text('Date/Time')),
              Provider.of<Data>(context,listen: false).eventFilter=='date'?SvgPicture.asset('assets/svg/yes.svg',height: 20,color: Colors.indigo,):Container(),
            ],
          ),),
        ],
        onSelected: (String value) {
          Provider.of<Data>(context,listen: false).changeEventFilter(value);
          setState(() { });
        });
  }


  @override
  void initState() {
    getLogData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: getLogData(),
      builder: (context, snapshot) {
        if(snapshot.hasData){
          List<LogData> objList=[];
          List<LogData> filteredList=[];

          snapshot.data.forEach((element) {
            LogData obj=new LogData();
            obj.name=element['content'].split("<br /><br>")[0];
            obj.speed=element['content'].split("<br /><br>")[1];
            obj.direction=element['content'].split("<br /><br>")[2];
            obj.location=element['content'].split("<br /><br>")[3];
            obj.date=element['content'].split("<br /><br>")[4];
            obj.event=element['content'].split("<br /><br>")[5];
            objList.add(obj);
          });

          if(Provider.of<Data>(context).eventFilter=='name'){
            while(objList.length!=0){
              filteredList=filteredList+(objList.where((element) => element.name==objList[0].name).toList());
              objList.removeWhere((element) => element.name==objList[0].name);
            }
          }
          if(Provider.of<Data>(context).eventFilter=='event'){
            while(objList.length!=0){
              filteredList=filteredList+(objList.where((element) => element.event==objList[0].event).toList());
              objList.removeWhere((element) => element.event==objList[0].event);
            }
          }
          if(Provider.of<Data>(context).eventFilter=='date'){
            while(objList.length!=0){
              filteredList=filteredList+(objList.where((element) => element.date==objList[0].date).toList());
              objList.removeWhere((element) => element.date==objList[0].date);
              filteredList=filteredList.reversed.toList();
            }
          }

          return Scaffold(
            backgroundColor:  Color.fromRGBO(247, 247, 247, 1),
            appBar: AppBar(title: Text('Event log'),actions: [openPopMenu()],),
            body: Container(child: ListView.builder(itemCount: filteredList.length,itemBuilder: (ctx,i){
              return Container(padding: EdgeInsets.only(bottom: 12,top: 12),decoration: BoxDecoration(border: Border(bottom: BorderSide(width:1,color:Colors.black26),
              ),),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(text: HTML.toTextSpan(context, filteredList[i].name,defaultTextStyle: TextStyle(decoration: TextDecoration.none,fontSize: 23,)),),
                  RichText(text: HTML.toTextSpan(context, filteredList[i].speed,defaultTextStyle: TextStyle(decoration: TextDecoration.none,fontSize: 23,)),),
                  RichText(text: HTML.toTextSpan(context, filteredList[i].direction,defaultTextStyle: TextStyle(decoration: TextDecoration.none,fontSize: 23,)),),
                  RichText(text: HTML.toTextSpan(context, filteredList[i].location,defaultTextStyle: TextStyle(decoration: TextDecoration.none,fontSize: 23,)),),
                  RichText(text: HTML.toTextSpan(context, filteredList[i].date,defaultTextStyle: TextStyle(decoration: TextDecoration.none,fontSize: 23,)),),
                  RichText(text: HTML.toTextSpan(context, filteredList[i].event,defaultTextStyle: TextStyle(decoration: TextDecoration.none,fontSize: 23,)),),
                ],
              )
                ,);
            }),),
          );
        }else{
          return Scaffold(
            backgroundColor:  Color.fromRGBO(247, 247, 247, 1),
            appBar: AppBar(title: Text('Event log'),),
            body: Center(
                child: CupertinoActivityIndicator(
                    radius: 20, animating: true)),
          );
        }
      }
    );
  }
}

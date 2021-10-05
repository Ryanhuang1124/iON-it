import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ion_it/pages/smartfence_page.dart';
import 'package:provider/provider.dart';
import 'package:ion_it/main.dart';



class SelectRadius extends StatefulWidget {
  final String name;
  @override
  _SelectRadiusState createState() => _SelectRadiusState();
  const SelectRadius({Key key,@required this.name}):super(key:key);

}

class _SelectRadiusState extends State<SelectRadius> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  Color.fromRGBO(247, 247, 247, 1),
      appBar: AppBar(title: Text('Radius'),),
      body: Container(child: Column(children: [
        SizedBox(height: MediaQuery.of(context).size.height/17,),
        Container(decoration: BoxDecoration(color: Colors.white,border: Border(top: BorderSide(width: 0.5,color: Colors.black26),bottom: BorderSide(width: 0.5,color: Colors.black26))),child: Column(children: [
          Padding(
            padding: const EdgeInsets.only(left:12.0),
            child: GestureDetector(onTap: (){
              SmartFenceData obj=Provider.of<Data>(context,listen: false).smartData[widget.name];
              obj.smartFenceRadius=100;
              Provider.of<Data>(context,listen: false).changeSmartFenceData(obj);
            }, child: Container(height: 50,decoration:BoxDecoration(border: Border(bottom: BorderSide(width: 1,color: Colors.black26))),child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('100  meters',style: TextStyle(fontFamily: 'Arial',fontSize: 22),),
                Visibility(visible:Provider.of<Data>(context).smartData[widget.name].smartFenceRadius==100,child: SvgPicture.asset('assets/svg/yes.svg',height: 20,color: Colors.indigo,)),
              ],
            ),)),
          ),
          Padding(
            padding: const EdgeInsets.only(left:12.0),
            child: GestureDetector(onTap: (){
              SmartFenceData obj=Provider.of<Data>(context,listen: false).smartData[widget.name];
              obj.smartFenceRadius=150;
              Provider.of<Data>(context,listen: false).changeSmartFenceData(obj);
            }, child: Container(height: 50,decoration:BoxDecoration(border: Border(bottom: BorderSide(width: 1,color: Colors.black26))),child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('150  meters',style: TextStyle(fontFamily: 'Arial',fontSize: 22),),
                Visibility(visible:Provider.of<Data>(context).smartData[widget.name].smartFenceRadius==150,child: SvgPicture.asset('assets/svg/yes.svg',height: 20,color: Colors.indigo,)),
              ],
            ),)),
          ),
          Padding(
            padding: const EdgeInsets.only(left:12.0),
            child: GestureDetector(onTap: (){
              SmartFenceData obj=Provider.of<Data>(context,listen: false).smartData[widget.name];
              obj.smartFenceRadius=200;
              Provider.of<Data>(context,listen: false).changeSmartFenceData(obj);
            }, child: Container(height: 50,decoration:BoxDecoration(border: Border(bottom: BorderSide(width: 1,color: Colors.black26))),child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('200  meters',style: TextStyle(fontFamily: 'Arial',fontSize: 22),),
                Visibility(visible:Provider.of<Data>(context).smartData[widget.name].smartFenceRadius==200,child: SvgPicture.asset('assets/svg/yes.svg',height: 20,color: Colors.indigo,)),
              ],
            ),)),
          ),
          Padding(
            padding: const EdgeInsets.only(left:12.0,),
            child: GestureDetector(onTap: (){
              SmartFenceData obj=Provider.of<Data>(context,listen: false).smartData[widget.name];
              obj.smartFenceRadius=250;
              Provider.of<Data>(context,listen: false).changeSmartFenceData(obj);
            }, child: Container(height: 50,decoration:BoxDecoration(border: Border(bottom: BorderSide(width: 1,color: Colors.white))),child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('250  meters',style: TextStyle(fontFamily: 'Arial',fontSize: 22),),
                Visibility(visible:Provider.of<Data>(context).smartData[widget.name].smartFenceRadius==250,child: SvgPicture.asset('assets/svg/yes.svg',height: 20,color: Colors.indigo,)),
              ],
            ),)),
          ),
        ],),)
      ],),),
    );
  }
}

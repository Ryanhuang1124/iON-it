import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ion_it/pages/edit_location_passing.dart';
import 'package:ion_it/pages/passing_by_record_page.dart';
import 'package:provider/provider.dart';
import 'package:ion_it/main.dart';





class SelectRadiusPassing extends StatefulWidget {
  final String jsonData;

  const SelectRadiusPassing({Key key,@required this.jsonData}):super(key:key);
  @override
  _SelectRadiusPassingState createState() => _SelectRadiusPassingState();
}

class _SelectRadiusPassingState extends State<SelectRadiusPassing> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  Color.fromRGBO(247, 247, 247, 1),
      appBar: AppBar(title: Text('Radius'),
      ),
      body: Container(child: Column(children: [
        SizedBox(height: MediaQuery.of(context).size.height/17,),
        Container(decoration: BoxDecoration(color: Colors.white,border: Border(top: BorderSide(width: 0.5,color: Colors.black26),bottom: BorderSide(width: 0.5,color: Colors.black26))),child: Column(children: [
          Padding(
            padding: const EdgeInsets.only(left:12.0),
            child: GestureDetector(onTap: (){
              Provider.of<Data>(context,listen: false).changePassingRadius(0.5);
            }, child: Container(height: 50,decoration:BoxDecoration(border: Border(bottom: BorderSide(width: 1,color: Colors.black26))),child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0.5  km',style: TextStyle(fontFamily: 'Arial',fontSize: 22),),
                Visibility(visible:Provider.of<Data>(context).passingRadius==0.5,child: SvgPicture.asset('assets/svg/yes.svg',height: 20,color: Colors.indigo,)),
              ],
            ),)),
          ),
          Padding(
            padding: const EdgeInsets.only(left:12.0),
            child: GestureDetector(onTap: (){

              Provider.of<Data>(context,listen: false).changePassingRadius(1);
            }, child: Container(height: 50,decoration:BoxDecoration(border: Border(bottom: BorderSide(width: 1,color: Colors.black26))),child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1  km',style: TextStyle(fontFamily: 'Arial',fontSize: 22),),
                Visibility(visible:Provider.of<Data>(context).passingRadius==1,child: SvgPicture.asset('assets/svg/yes.svg',height: 20,color: Colors.indigo,)),
              ],
            ),)),
          ),
          Padding(
            padding: const EdgeInsets.only(left:12.0),
            child: GestureDetector(onTap: (){
              Provider.of<Data>(context,listen: false).changePassingRadius(1.5);
            }, child: Container(height: 50,decoration:BoxDecoration(border: Border(bottom: BorderSide(width: 1,color: Colors.black26))),child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1.5  km',style: TextStyle(fontFamily: 'Arial',fontSize: 22),),
                Visibility(visible:Provider.of<Data>(context).passingRadius==1.5,child: SvgPicture.asset('assets/svg/yes.svg',height: 20,color: Colors.indigo,)),
              ],
            ),)),
          ),
          Padding(
            padding: const EdgeInsets.only(left:12.0,),
            child: GestureDetector(onTap: (){
              Provider.of<Data>(context,listen: false).changePassingRadius(2);
            }, child: Container(height: 50,decoration:BoxDecoration(border: Border(bottom: BorderSide(width: 1,color: Colors.white))),child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('2  km',style: TextStyle(fontFamily: 'Arial',fontSize: 22),),
                Visibility(visible:Provider.of<Data>(context).passingRadius==2,child: SvgPicture.asset('assets/svg/yes.svg',height: 20,color: Colors.indigo,)),
              ],
            ),)),
          ),
        ],),)
      ],),),
    );
  }
}

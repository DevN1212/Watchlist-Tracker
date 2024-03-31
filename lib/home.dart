import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'rectangle_container.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<List<dynamic>> originalList = [];

  void _loadcsv() async{
    final _rawdata=await rootBundle.loadString("assets/file.csv");
    final List<List<dynamic>> _list=const CsvToListConverter().convert(_rawdata);
    setState(() {
      originalList=_list;
    });
  }
  @override
  void initState(){
    super.initState();
    _loadcsv();
  }
  @override
  Widget build(BuildContext context) {
    List<int> sortedIndices = List.generate(originalList.length, (index) => index);
    sortedIndices.sort((a, b) => originalList[a][2].compareTo(originalList[b][2]));

    return Scaffold(
      appBar: AppBar(
        title: Text("Market"),
      ),
      body: Column(
        children: [
          Container(
            child: Text("Box"),
            height: 50,
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              itemCount: originalList.length,
              itemBuilder: (context, index) {
                print(originalList[index][1]);
                print(originalList[index][2]);
                final int sortedIndex = sortedIndices[index];
                print(originalList[sortedIndex][0]);
                print(originalList[sortedIndex][2]);
                return RectangleContainer(
                  indexCsv:originalList[sortedIndex][0],
                  name: originalList[sortedIndex][1],
                  qty: originalList[sortedIndex][2],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

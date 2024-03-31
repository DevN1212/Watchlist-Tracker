import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class RectangleContainer extends StatefulWidget {
  final String name;
  final int qty;
  final int indexCsv;

  RectangleContainer({
    required this.name,
    required this.qty,
    required this.indexCsv,
  });

  @override
  State<RectangleContainer> createState() => _RectangleContainerState();
}

class _RectangleContainerState extends State<RectangleContainer> {
  double price = 0;
  double prevPrice = 0;
  Color? backgroundColor = Colors.lightBlueAccent[100];
  late String csvFilePath;

  @override
  void initState() {
    super.initState();
    fetchPriceFromCSV();
    Timer.periodic(Duration(seconds: 10), (timer) {
      fetchPrice();
    });
  }

  Future<void> fetchPriceFromCSV() async {
    try {
      final File file = await getCsvFile();
      final rows = csvToList(await file.readAsLines());

      if (widget.indexCsv >= 0 && widget.indexCsv < rows.length) {
        final rowData = rows[widget.indexCsv];
        print("Raw data from CSV: ${rowData[3]}");
        setState(() {
          price = int.tryParse(rowData[3])?.toDouble() ?? 0.0;
        });
      }
    } catch (e) {
      print("Error reading CSV: $e");
    }
  }

  Future<File> getCsvFile() async {
    final String assetPath = 'assets/file.csv';
    final ByteData data = await rootBundle.load(assetPath);
    final List<int> bytes = data.buffer.asUint8List();
    final String tempPath = (await getTemporaryDirectory()).path;
    final File tempFile = File('$tempPath/file.csv');
    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }


  List<List<dynamic>> csvToList(List<String> csvLines) {
    return csvLines.map((line) => line.split(',')).toList();
  }

  Future<void> updateCsvPrice(double newPrice) async {
    try {
      final File file = await getCsvFile();
      List<List<dynamic>> rows = csvToList(await file.readAsLines());
      if (widget.indexCsv >= 0 && widget.indexCsv < rows.length) {
        final rowData = rows[widget.indexCsv];
        rowData[2] = newPrice as String; // Update price in the row
        await file.writeAsString(rows.map((row) => row.join(',')).join('\n'));
      }
    } catch (e) {
      print("Error updating CSV: $e");
    }
  }

  Future<void> fetchPrice() async {
    final response = await http.post(
      Uri.parse("http://10.0.2.2:5000/getliveprice"),
      body: json.encode({'Symbol': widget.name}),
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      final double priceValue = decoded['price'] as double;

      if (prevPrice != 0) {
        if (priceValue < prevPrice) {
          backgroundColor = Colors.red;
          Timer(Duration(seconds: 1), () {
            setState(() {
              backgroundColor = Colors.lightBlueAccent[100];
            });
          });
        } else if (priceValue > prevPrice) {
          backgroundColor = Colors.green;
          Timer(Duration(seconds: 1), () {
            setState(() {
              backgroundColor = Colors.lightBlueAccent[100];
            });
          });
        }
      }

      prevPrice = priceValue;
      setState(() {
        price = priceValue;
      });

      await updateCsvPrice(priceValue); // Update price in CSV
    } else {
      throw Exception('Failed to load price');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(2),
      child: Container(
        height: 200,
        color: backgroundColor,
        child: Center(
          child: Text(
            "${widget.name} ${widget.qty} Price: $price",
            style: TextStyle(
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }
}

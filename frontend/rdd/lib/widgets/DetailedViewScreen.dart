import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rdd/objects/capturedImageList.dart';
import 'package:rdd/widgets/CapturedImageMap.dart';
import 'package:rdd/widgets/MyPainter.dart';

class DetailedViewScreen extends StatelessWidget {
  final CapturedImageList capturedImageList;
  final double totalKmTravelled;

  DetailedViewScreen(
      {required this.capturedImageList, required this.totalKmTravelled});

  @override
  Widget build(BuildContext context) {
    // Calculate statistics
    Map<String, int> damageClassCounts = capturedImageList.getDamagesPerClass();
    Map<String, int> damagesForImg = {};

    return Scaffold(
      appBar: AppBar(title: Text("Detailed View")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Statistics
            Column(
              children: [
                for (var entry in damageClassCounts.entries)
                  Text('Class: ${entry.key} - Total damages: ${entry.value}'),
                Text('Total km travelled: $totalKmTravelled'),
                Text(
                    'Start to end destination: ${capturedImageList.start_locality} to ${capturedImageList.end_locality}'),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => CapturedImageMap(
                            capturedImageLists: [capturedImageList])));
                  },
                  child: Text('Show on Map'),
                ),
              ],
            ),
            Divider(height: 20, thickness: 2, color: Colors.black),
            // Image list
            Column(
              children: capturedImageList.images.map((image) {
                return Column(
                  children: [
                    // Display the image
                    FutureBuilder<ui.Image>(
                      future: loadImage(image.imagePath),
                      builder: (BuildContext context,
                          AsyncSnapshot<ui.Image> snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          if (snapshot.hasData) {
                            return FittedBox(
                              fit: BoxFit.contain,
                              child: SizedBox(
                                height: snapshot.data!.height.toDouble(), //720,
                                width: snapshot.data!.width.toDouble(), //480,
                                child: CustomPaint(
                                  painter:
                                      MyPainter(snapshot.data!, image.bboxes),
                                  child: Container(),
                                ),
                              ),
                            );
                          }
                          return Text('Error loading image');
                        }
                        return CircularProgressIndicator();
                      },
                    ),

                    //Image.file(File(image.imagePath)),
                    // Display the number of damages for each class

                    for (var bbox in image.bboxes)
                      Text('Class: ${bbox['tag']} - Damages: ${1}')
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

Future<Uint8List> loadImageAsByteList(String imagePath) async {
  ByteData byteData = await rootBundle.load(imagePath);
  return byteData.buffer.asUint8List();
}

Future<ui.Image> loadImage(String imagePath) async {
  final Uint8List data = await File(imagePath).readAsBytes();
  //Uint8List data = await loadImageAsByteList("assets/Sweden_000047.jpg");
  final Completer<ui.Image> completer = Completer();
  ui.decodeImageFromList(data, (ui.Image img) {
    return completer.complete(img);
  });
  return completer.future;
}

import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class MyPainter extends CustomPainter {
  ui.Image image;
  List<Map<String, dynamic>> bboxes; // List containing all bbox data

  MyPainter(this.image, this.bboxes);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the image on the canvas
    canvas.drawImage(image, Offset.zero, Paint());

    // Create a paint object to style the bbox
    Paint paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke; // Use stroke for empty box

    // Iterate over all bboxes and draw each one
    for (var bboxData in bboxes) {
      List bbox = bboxData['box'];
      String className = bboxData['tag'];
      print("Drawing bbox: $bbox");
      // Create a rectangle with the bbox coordinates

      Rect rect = Rect.fromLTWH(
        bbox[0].toDouble(), // Left
        bbox[1].toDouble(), // Top
        bbox[2].toDouble() - bbox[0].toDouble(), // Width
        bbox[3].toDouble() - bbox[1].toDouble(), // Height
      );

      // Draw the bbox on the canvas
      canvas.drawRect(rect, paint);

      // Draw the class of damage
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: className,
          style: TextStyle(color: Colors.red, fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      );

      // Layout the text
      textPainter.layout();

      // Draw the text on the canvas
      textPainter.paint(canvas, Offset(bbox[0].toDouble(), bbox[1].toDouble()));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

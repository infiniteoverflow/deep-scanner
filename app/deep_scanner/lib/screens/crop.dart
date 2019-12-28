import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:deep_scanner/core/crop_polygon.dart';
import 'package:deep_scanner/core/scanner.dart';
import 'package:deep_scanner/screens/result_display.dart';
import 'package:deep_scanner/widgets/crop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CropScreen extends StatefulWidget {
  final ImageSource imageSource;

  CropScreen({this.imageSource});

  @override
  State<StatefulWidget> createState() {
    return _CropScreenState();
  }
}

class _CropScreenState extends State<CropScreen> {
  CropPolygon polygon;
  File imgFile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.clear),
            tooltip: "Cancel",
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text("Crop image"),
          centerTitle: true,
          actions: <Widget>[
            IconButton(
              onPressed: () async {
                final bytes = await Scanner.warpCrop(
                    imageFile: this.imgFile, cropPolygon: this.polygon);
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return ResultDisplayScreen(bytes: bytes);
                }));
              },
              icon: Icon(Icons.done),
              tooltip: "Crop image",
            )
          ],
        ),
        body: FutureBuilder(
          future: _pickImage(),
          builder:
              (BuildContext context, AsyncSnapshot<ui.Image> asyncSnapshot) {
            if (asyncSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            RenderBox renderBox = context.findRenderObject();

            return Container(
                width: double.infinity,
                height: double.infinity,
                child: Crop(
                  image: asyncSnapshot.data,
                  size: renderBox.size,
                  onCropPolygonUpdate: (CropPolygon polygon) {
                    this.polygon = polygon;
                    debugPrint(
                        "${polygon.topLeft} ${polygon.bottomRight} IMG: ${asyncSnapshot.data.width} ${asyncSnapshot.data.height}");
                  },
                ));
          },
        ));
  }

  Future<ui.Image> _pickImage() async {
    final File tmpImageFile =
        await ImagePicker.pickImage(source: widget.imageSource);
    final String baseName = p.basename(tmpImageFile.path);
    final String path = (await getApplicationDocumentsDirectory()).path;
    final File imageFile = await tmpImageFile.copy(p.join(path, baseName));

    this.imgFile = imageFile;
//    Uint8List bytes = await Scanner.warpCrop(imageFile: imageFile, cropPolygon: CropPolygon());

    final Completer<ui.Image> completer = Completer();
//    ui.decodeImageFromList(bytes, (ui.Image img) {
//      return completer.complete(img);
//    });
    ui.decodeImageFromList(await imageFile.readAsBytes(), (ui.Image img) {
      return completer.complete(img);
    });
    return await completer.future;
  }
}

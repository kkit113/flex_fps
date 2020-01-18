import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:crclib/crclib.dart';
import 'package:qr_flutter/qr_flutter.dart';
import './disclaimer.dart';
import '../models/fps_content.dart';

class SelectScreen extends StatefulWidget {
  @override
  _SelectScreenState createState() => _SelectScreenState();
}

class _SelectScreenState extends State<SelectScreen> {
  String barcode = "";
  String strData = "";

  GlobalKey globalKey = new GlobalKey();
  TextEditingController strDataController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController remarkController = TextEditingController();
  bool allowEditAmount = false;

  double bodyHeight, bodyWidth;
  String crc16text,
      strAmount,
      strOriginalField54,
      strField26,
      strOriginalField26;
  String strShareMessage = '';

  _appBar() {
    return AppBar(
      title: Text('Flexible FPS payment'),
      actions: <Widget>[
//        Row(
//          mainAxisSize: MainAxisSize.min,
//          mainAxisAlignment: MainAxisAlignment.end,
//          children: <Widget>[
//            IconButton(
//              onPressed: null,
//              icon: Icon(Icons.photo_library),
//            ),
//          ],
//        ),
      ],
    );
  }

  _body() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          margin: EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: RepaintBoundary(
                  key: globalKey,
                  child: QrImage(
                    data: strDataController.text,
                    size: 0.8 * bodyWidth < 0.4 * bodyHeight
                        ? 0.8 * bodyWidth
                        : 0.4 * bodyHeight,
                    backgroundColor: allowEditAmount == true
                        ? Colors.grey[100]
                        : Colors.white,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
              Divider(
                height: 10,
                color: Colors.cyan,
                thickness: 2,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    children: <Widget>[
                      Container(
                        width: bodyWidth * 0.8,
                        padding: EdgeInsets.only(bottom: 10),
                        child: TextField(
                          controller: strDataController,
                          decoration: InputDecoration(labelText: "FPS Data"),
                          readOnly: true,
                          keyboardType: TextInputType.multiline,
                          maxLines: 4,
                        ),
                      ),
                      SizedBox(height: 15,),
                      Container(
                        width: bodyWidth * 0.8,
                        child: Row(
                          children: <Widget>[

                            Text('Editable \namount:'),
                            Checkbox(
                                value: allowEditAmount,
                                onChanged: _changeAmountEditable),
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                controller: amountController,
                                decoration: InputDecoration(labelText: "Amount"),
                                onChanged: (text) {
                                  crc16text = text;
                                  _changeAmount(text);
                                },
                              ),
                            ),],
                        ),
                      ),
//                      Container(
//                        width: bodyWidth * 0.9,
//                        child: CheckboxListTile(
//                          value: allowEditAmount,
//                          onChanged: _changeAmountEditable,
//                          title: TextField(
//                            keyboardType: TextInputType.number,
//                            controller: amountController,
//                            decoration: InputDecoration(labelText: "Amount"),
//                            onChanged: (text) {
//                              crc16text = text;
//                              _changeAmount(text);
//                            },
//                          ),
//                          subtitle: Align(
//                              alignment: Alignment.centerRight,
//                              child: Text('Check to allow edit amount')),
//                        ),
//                      ),
                    SizedBox(height: 15,),
                      Container(
                        width: bodyWidth * 0.8,
                        padding: EdgeInsets.only(bottom: 10),
                        child: TextField(
                          keyboardType: TextInputType.text,
                          controller: remarkController,
                          decoration:
                              InputDecoration(labelText: "Message"),
                          onChanged: (text) {
                            strShareMessage = text;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 25,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  FlatButton(
                    onPressed: scan,
                    child: Text('Scan'),
                  ),
//                  FlatButton(
//                    onPressed: () {
//                      String raw = strDataController.text
//                          .substring(0, strDataController.text.length - 4);
//                      String replaceAmount = '54' +
//                          amountController.text.length
//                              .toString()
//                              .padLeft(2, '0') +
//                          amountController.text;
//                      print('replace: $replaceAmount');
//                      raw = raw.replaceAll(strOriginalField54, replaceAmount);
//                      String c = calculateCRC16(raw);
//                      setState(() {
//                        strOriginalField54 = replaceAmount;
//                        strDataController.text = raw + c;
//                      });
//                    },
//                    child: Text('Generate'),
//                  ),
                  FlatButton(
                    onPressed: _captureAndSharePng,
                    child: Text('Share'),
                  ),
                  FlatButton(
                    onPressed: () => exit(0),
                    child: Text('Exit'),
                  )
                ],
              ),
              SizedBox(
                height: 20,
              ),
              FlatButton(
                onPressed: () {
                  Disclaimer().showDisclaimer(context);
                },
                child: Text(
                  'Disclaimer',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              SizedBox(height: 25,),
            ],
          ),
        ),
      ),
    );
  }

  String calculateCRC16(String data) {
    String crc = Crc16CCITT()
        .convert(utf8.encode(data))
        .toInt()
        .toRadixString(16)
        .toUpperCase();

    return crc.padLeft(4, '0');
  }

  Future scan() async {
    try {
      String barcode = await BarcodeScanner.scan();
      try {
        strData = _fpsCodeString(_extractFPSDetail(barcode));
      } catch (e) {
        print('Error: $e');
      }
      setState(() {
        strDataController.text = strData;
        amountController.text = strAmount;
      });
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        setState(() {
          this.barcode = 'The user did not grant the camera permission!';
        });
      } else {
        setState(() => this.barcode = 'Unknown error: $e');
      }
    } on FormatException {
      setState(() => this.barcode =
          'null (User returned using the "back"-button before scanning anything. Result)');
    } catch (e) {
      setState(() => this.barcode = 'Unknown error: $e');
    }
  }

  String _fpsCodeString(FpsContent fpsContent) {
    return fpsContent.toString();
  }

  FpsContent _extractFPSDetail(String data) {
    int dataLength = data.length;

    int fieldNumberPointer = 0;
    int fieldLengthPointer = 0;
    int fieldValuePointer = 0;

    String fieldNumber, fieldLength, fieldValue;

    List<FpsItem> fpsItemList = List<FpsItem>();
    bool end = false;
    for (var d = 0; d <= dataLength; d++) {
      if (end) break;
      if (fieldValuePointer == 0 &&
          fieldLengthPointer == 0 &&
          fieldNumberPointer < 2) {
        fieldNumber = data.substring(d - fieldNumberPointer, d + 1);
        fieldNumberPointer++;
      } else if (fieldValuePointer == 0 &&
          fieldLengthPointer < 2 &&
          fieldNumberPointer == 2) {
        fieldLength = data.substring(d - fieldLengthPointer, d + 1);
        fieldLengthPointer++;
      } else if (fieldValuePointer < int.parse(fieldLength) &&
          fieldLengthPointer == 2 &&
          fieldNumberPointer == 2) {
        fieldValue = data.substring(d - fieldValuePointer, d + 1);
        fieldValuePointer++;
      } else {
        FpsItem item = FpsItem(
            fieldIndicator: fieldNumber,
            fieldLength: fieldLength,
            fieldValue: fieldValue);
        if (d == dataLength) end = true;

        d = d - 1;

        if (fieldNumber == '54') {
          strAmount = fieldValue;
          strOriginalField54 = fieldNumber + fieldLength + fieldValue;
        }

        if (fieldNumber == '26') {
          allowEditAmount = fieldValue.contains('06011');
          strOriginalField26 = fieldNumber + fieldLength + fieldValue;
        }

        try {
          fpsItemList.add(item);
        } catch (e) {
          print('addItem Error: $e');
        }

        fieldNumber = "";
        fieldLength = "";
        fieldValue = "";
        fieldNumberPointer = 0;
        fieldLengthPointer = 0;
        fieldValuePointer = 0;
//        fpsSubItemList.clear();
      }
    }

    FpsContent fpsContent = FpsContent(fpsItemList);
    return fpsContent;
  }


  FpsItem fpsItem (String fieldNumber, String originalLength, String fieldValue)
  {
    List<FpsSubItem> subItemList = List<FpsSubItem>();
    FpsItem item;
        int fieldSubIndexPointer = 0;
    int fieldSubIndexLengthPointer = 0;
    int fieldSubIndexValuePointer = 0;
String fieldSubIndex, fieldSubIndexLength, fieldSubIndexValue;
    bool subItemEnd = false;

    if(int.parse(originalLength) == fieldValue.length) {

      for(int i =0; i<= fieldValue.length; i++){
        if(subItemEnd)break;
        if (fieldSubIndexValuePointer == 0 &&
            fieldSubIndexLengthPointer == 0 &&
            fieldSubIndexPointer < 2) {
          fieldSubIndex = fieldValue.substring(i - fieldSubIndexPointer, i + 1);
          fieldSubIndexPointer++;
        } else if (fieldSubIndexValuePointer == 0 &&
            fieldSubIndexLengthPointer < 2 &&
            fieldSubIndexPointer == 2) {
          fieldSubIndexLength = fieldValue.substring(i - fieldSubIndexLengthPointer, i + 1);
          fieldSubIndexLengthPointer++;
        } else if (fieldSubIndexValuePointer < int.parse(fieldSubIndexLength) &&
            fieldSubIndexLengthPointer == 2 &&
            fieldSubIndexPointer == 2) {
          fieldSubIndexValue = fieldValue.substring(i - fieldSubIndexValuePointer, i + 1);
          fieldSubIndexValuePointer++;
        } else {
          if (i == fieldValue.length) subItemEnd = true;

          FpsSubItem subItem = FpsSubItem(fieldSubIndex: fieldSubIndex,
              fieldSubIndexLength: fieldSubIndexLength,
              fieldSubIndexValue: fieldSubIndexValue);

          i = i - 1;

          try {
            subItemList.add(subItem);
          } catch (e) {
            print('addItem Error: $e');
          }

          fieldSubIndex = "";
          fieldSubIndexLength = "";
          fieldSubIndexValue = "";
          fieldSubIndexPointer = 0;
          fieldSubIndexLengthPointer = 0;
          fieldSubIndexValuePointer = 0;
        }
      }
      item = FpsItem(
        fieldIndicator: fieldNumber,
        fieldLength: originalLength,
//        fieldValue: fieldValue,
        subItem: subItemList,
      );
    }

    return item;
  }


  Future<void> _captureAndSharePng() async {
    try {
      RenderRepaintBoundary boundary =
          globalKey.currentContext.findRenderObject();
      var image = await boundary.toImage();
      ByteData byteData = await image.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData.buffer.asUint8List();

      String fileName = DateTime.now().toString().substring(0, 19);

//      final tempDir = await getApplicationDocumentsDirectory();
//      final file = await new File('${tempDir.path}/$fileName.png').create();
//      await file.writeAsBytes(pngBytes);

//      String path = await ImageSave.saveImage('image/png', pngBytes);

      await Share.file('FPS QR', '$fileName.png', pngBytes, 'image/png',
          text: strShareMessage);

//      final channel = const MethodChannel('channel:me.albie.share/share');
//      channel.invokeMethod('shareFile', '$fileName.png');

    } catch (e) {
      print(e.toString());
    }
  }

  void _changeAmountEditable(bool value) {
    if (strOriginalField26 != '' && strOriginalField26 != null) {
      if (value && !strOriginalField26.contains('06011')) {
        strField26 = strOriginalField26 + '06011';
//        print('$value: $strField26');
      } else if (!value && strOriginalField26.contains('06011')) {
        strField26 = strOriginalField26.replaceAll('06011', '');
//        print('$value: $strField26');
      }

      int newLength = strField26.length - 4;
      int originalLength = int.parse(strField26.substring(2, 4));
      strField26 = strField26.replaceFirst('26$originalLength', '26$newLength');
      strData = strData.replaceAll(strOriginalField26, strField26);

      strData = _reCalculateCRC(strData);

//      print('$strField26');
//      print('$strData');
    } else {
      allowEditAmount = false;
    }

    setState(() {
      allowEditAmount = value;
      strDataController.text = strData;
    });
    strOriginalField26 = strField26;
  }

  void _changeAmount(String newAmount) {
    newAmount = newAmount.trim();

    String strField54 =
        '54' + newAmount.length.toString().padLeft(2, '0') + newAmount;
    strData = strData.replaceAll(strOriginalField54, strField54);
    strOriginalField54 = strField54;
    setState(() {
      strDataController.text = _reCalculateCRC(strData);
    });
  }

  String _reCalculateCRC(String newData) {
    newData = newData.substring(0, strData.length - 4);
    return newData + calculateCRC16(newData);
  }

  @override
  Widget build(BuildContext context) {
    bodyHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).viewInsets.bottom;
    bodyWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: _appBar(),
      body: _body(),
    );
  }
}

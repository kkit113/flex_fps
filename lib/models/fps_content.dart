import 'package:flutter/foundation.dart';

class FpsContent {
  List<FpsItem> data;

  FpsContent(this.data);

  @override
  String toString() {
    String strData = "";
    for (int i = 0; i < data.length; i++) {
      strData = strData + data[i].toString();
    }

    return strData;
  }
}

class FpsItem {
  String fieldIndicator;
  String fieldLength;
  String fieldValue;
  List<FpsSubItem> subItem;

  FpsItem(
      {@required this.fieldIndicator,
      @required this.fieldLength,
      this.fieldValue,
      this.subItem});

  @override
  String toString() {
    String strData = "";
    if (subItem!= null && subItem.length != null) {
      for (int i = 0; i < subItem.length; i++) {
        strData = strData + subItem[i].toString();
      }
    }
    return '$fieldIndicator$fieldLength$fieldValue$strData';
  }
}

class FpsSubItem {
  String fieldSubIndex;
  String fieldSubIndexLength;
  String fieldSubIndexValue;

  FpsSubItem({
    this.fieldSubIndex,
    this.fieldSubIndexLength,
    this.fieldSubIndexValue,
  });

  @override
  String toString() {
    return '$fieldSubIndex$fieldSubIndexLength$fieldSubIndexValue';
  }
}
//26
// 00 Url
// 01 Bank Code
// 02 FPS ID
// 03 Mobile phone no
// 04 email address
// 05 expiry datetime (yyMMddhhmmss)
// 06 (06011) allow edit

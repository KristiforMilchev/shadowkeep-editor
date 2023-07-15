import 'package:flutter/material.dart';

class TextLineStyles {
  int anchor;
  int column;
  bool isBold;
  bool isUnderlined;
  Color? hasColor;

  TextLineStyles({
    required this.anchor,
    required this.column,
    required this.isBold,
    required this.hasColor,
    required this.isUnderlined,
  });
}

import 'package:flutter/material.dart';

class TextLine {
  String text;
  int type;
  TextAlign align;
  bool hasColor;
  Color? color;
  int size;
  bool isBold;

  TextLine({
    this.text = '',
    required this.type,
    required this.align,
    this.color,
    required this.hasColor,
    this.size = 14,
    this.isBold = false,
  });
}

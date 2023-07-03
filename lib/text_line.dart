import 'package:flutter/material.dart';

class TextLine {
  String text;
  int type;
  TextAlign align;
  bool hasColor;
  Color? color;

  TextLine({
    this.text = '',
    required this.type,
    required this.align,
    this.color,
    required this.hasColor,
  });
}

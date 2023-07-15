import 'package:flutter/material.dart';
import 'package:shadowkeep_editor/text_line_styles.dart';

class TextLine {
  String text;
  int type;
  TextAlign align;
  bool hasColor;
  Color? color;
  int size;
  bool isBold;
  List<TextLine>? listLines;
  int lineNumber;
  List<TextLineStyles>? lineStyles;

  bool isUnderlined;
  TextLine(
      {this.text = '',
      required this.type,
      required this.align,
      this.color,
      required this.hasColor,
      this.size = 14,
      this.isBold = false,
      this.listLines,
      this.lineNumber = 0,
      this.isUnderlined = false,
      this.lineStyles});
}

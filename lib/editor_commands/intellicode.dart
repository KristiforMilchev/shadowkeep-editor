import 'package:flutter/material.dart';
import 'package:shadowkeep_editor/cursor.dart';
import 'package:shadowkeep_editor/editor_commands/general.dart';
import 'package:shadowkeep_editor/text_line.dart';
import 'package:shadowkeep_editor/text_line_styles.dart';

class Intellicode {
  static onElementSelected(
      String value, int type, List<TextLine> lines, Cursor cursor) {
    Color? color;

    General.ensureInitialized(lines, cursor);

    switch (type) {
      case 1:
        color = Colors.blue;
        break;
      case 2:
        color = Colors.green;
        break;
    }
    lines[cursor.line].lineStyles!.add(
          TextLineStyles(
            anchor: cursor.column,
            column: cursor.column - value.length,
            hasColor: color,
          ),
        );
  }
}

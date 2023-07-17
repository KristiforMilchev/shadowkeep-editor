import 'package:flutter/material.dart';
import 'package:shadowkeep_editor/cursor.dart';
import 'package:shadowkeep_editor/text_line.dart';

class Quoutes {
  static apply(Cursor cursor, List<TextLine> lines) {
    if (!cursor.hasSelection()) {
      Quoutes.applyDoubleLine(lines, cursor);
      return;
    }

    Quoutes.applyDoubleSelectioon(cursor, lines);
  }

  static applyDoubleSelectioon(Cursor cursor, List<TextLine> lines) {
    if (!cursor.hasSelection()) return;

    var left = lines[cursor.line].text.substring(0, cursor.column);
    var right = lines[cursor.line]
        .text
        .substring(cursor.anchorColumn, lines[cursor.line].text.length);
    String quouteContent =
        lines[cursor.line].text.substring(cursor.column, cursor.anchorColumn);

    if (quouteContent.characters.first == '"') {
      var noQuoutes = quouteContent.substring(0, quouteContent.length - 1);

      // ignore: prefer_single_quotes
      lines[cursor.line].text = "$left $noQuoutes $right";
    } else {
      // ignore: prefer_single_quotes
      lines[cursor.line].text = "$left \"$quouteContent\" $right";
    }
  }

  static applyDoubleLine(List<TextLine> lines, Cursor cursor) {
    var currentLine = lines[cursor.line].text;
    if (currentLine.characters.first == '"') {
      var noQuoutes = lines[cursor.line]
          .text
          .substring(1, lines[cursor.line].text.length - 1);

      lines[cursor.line].text = noQuoutes;
    } else {
      // ignore: prefer_single_quotes
      lines[cursor.line].text = "\"${lines[cursor.line].text}\"";
    }
  }
}

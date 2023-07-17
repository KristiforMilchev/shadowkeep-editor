import 'package:flutter/material.dart';
import 'package:shadowkeep_editor/cursor.dart';
import 'package:shadowkeep_editor/editor_commands/general.dart';
import 'package:shadowkeep_editor/text_line.dart';

class CursorCommands {
  static void moveCursorToStartOfDocument(
    List<TextLine> lines,
    Cursor cursor, {
    bool keepAnchor = false,
  }) {
    cursor.line = 0;
    cursor.column = 0;
    General.validateCursor(lines, cursor, keepAnchor);
  }

  static void moveCursorToEndOfDocument(List<TextLine> lines, Cursor cursor,
      {bool keepAnchor = false}) {
    cursor.line = lines.length - 1;
    cursor.column = lines[cursor.line].text.length;
    General.validateCursor(lines, cursor, keepAnchor);
  }

  static void moveCursorToStartOfLine(List<TextLine> lines, Cursor cursor,
      {bool keepAnchor = false}) {
    cursor.column = 0;
    General.validateCursor(lines, cursor, keepAnchor);
  }

  static void moveCursorToEndOfLine(List<TextLine> lines, Cursor cursor,
      {bool keepAnchor = false}) {
    cursor.column = lines[cursor.line].text.length;
    General.validateCursor(lines, cursor, keepAnchor);
  }

  static void moveCursorUp(List<TextLine> lines, Cursor cursor,
      {int count = 1, bool keepAnchor = false}) {
    cursor.line = cursor.line - count;
    General.validateCursor(lines, cursor, keepAnchor);
  }

  static void moveCursorDown(List<TextLine> lines, Cursor cursor,
      {int count = 1, bool keepAnchor = false}) {
    cursor.line = cursor.line + count;
    General.validateCursor(lines, cursor, keepAnchor);
  }

  static void createLineAtCursor(List<TextLine> lines, Cursor cursor) {
    lines.insert(
      cursor.line,
      TextLine(type: 1, align: TextAlign.start, hasColor: false),
    );
  }

  static void moveCursor(
      int line, int column, List<TextLine> lines, Cursor cursor,
      {bool keepAnchor = false}) {
    cursor.line = line;
    cursor.column = column;
    General.validateCursor(lines, cursor, keepAnchor);
  }

  static void moveCursorLeft(List<TextLine> lines, Cursor cursor,
      {int count = 1, bool keepAnchor = false}) {
    cursor.column = cursor.column - count;
    if (cursor.column < 0) {
      moveCursorUp(lines, cursor, keepAnchor: keepAnchor);
      moveCursorToEndOfLine(lines, cursor, keepAnchor: keepAnchor);
    }
    General.validateCursor(lines, cursor, keepAnchor);
  }

  static void moveCursorLeftList(
      List<TextLine> lines, Cursor cursor, int count, bool keepAnchor) {
    cursor.column--;
    if (cursor.column >
        lines[cursor.line]
            .listLines![lines[cursor.line].lineNumber]
            .text
            .length) {
      moveCursorDown(lines, cursor, keepAnchor: keepAnchor);
      moveCursorToStartOfLine(lines, cursor, keepAnchor: keepAnchor);
    }
    General.validateCursor(lines, cursor, keepAnchor);
  }

  static void moveCursorRightList(List<TextLine> lines, Cursor cursor,
      {int count = 1, bool keepAnchor = false}) {
    cursor.column = cursor.column + count;

    print(cursor.column);
    if (cursor.column >
        lines[cursor.line]
            .listLines![lines[cursor.line].lineNumber]
            .text
            .length) {
      moveCursorDown(lines, cursor, keepAnchor: keepAnchor);
      moveCursorToStartOfLine(lines, cursor, keepAnchor: keepAnchor);
    }
    General.validateCursor(lines, cursor, keepAnchor);
  }

  static void moveCursorRight(List<TextLine> lines, Cursor cursor,
      {int count = 1, bool keepAnchor = false}) {
    cursor.column = cursor.column + count;
    if (cursor.column > lines[cursor.line].text.length) {
      moveCursorDown(lines, cursor, keepAnchor: keepAnchor);
      moveCursorToStartOfLine(lines, cursor, keepAnchor: keepAnchor);
    }
    General.validateCursor(lines, cursor, keepAnchor);
  }

  static void moveCursorLeftMarkWord(List<TextLine> lines, Cursor cursor,
      {required bool keepAnchor}) {
    var line = lines[cursor.line].text;
    var words = line
        .substring(0, cursor.anchorColumn)
        .split(' ')
        .where((element) => element.isNotEmpty)
        .toList();

    moveCursorLeft(
      count: words.last.length + 1,
      lines,
      cursor,
      keepAnchor: keepAnchor,
    );
  }

  static void moveCursorRightMarkWord(List<TextLine> lines, Cursor cursor,
      {required bool keepAnchor}) {
    var line = lines[cursor.line].text;
    var words = line
        .substring(cursor.anchorColumn)
        .split(' ')
        .where((element) => element.isNotEmpty)
        .toList();

    moveCursorRight(
      count: words.first.length + 1,
      lines,
      cursor,
      keepAnchor: keepAnchor,
    );
  }
}

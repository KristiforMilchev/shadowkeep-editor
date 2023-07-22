import 'package:flutter/services.dart';
import 'package:shadowkeep_editor/cursor.dart';
import 'package:shadowkeep_editor/document.dart';
import 'package:shadowkeep_editor/editor_commands/cursor_commands.dart';
import 'package:shadowkeep_editor/text_line.dart';

class General {
  static bool isCapsLockOn() {
    return HardwareKeyboard.instance.lockModesEnabled
        .contains(KeyboardLockMode.capsLock);
  }

  static ensureInitialized(List<TextLine> lines, Cursor cursor) {
    if (lines[cursor.line].lineStyles == null) {
      lines[cursor.line].lineStyles = [];
    }
  }

  static deleteSelectedText(List<TextLine> lines, Cursor cursor) {
    if (!cursor.hasSelection()) {
      return;
    }

    Cursor cur = cursor.normalized();
    List<String> res = selectedLines(lines, cursor);
    if (res.length == 1) {
      print(cur.anchorColumn - cur.column);
      deleteText(
        lines,
        cursor,
        numberOfCharacters: cur.anchorColumn - cur.column,
      );
      clearSelection(cursor);
      return;
    }

    if (lines.elementAtOrNull(cur.line) == null) {
      CursorCommands.createLineAtCursor(lines, cursor);
    }

    String l = lines[cur.line].text;
    String left = l.substring(0, cur.column);
    l = lines[cur.anchorLine].text;
    String right = l.substring(cur.anchorColumn);

    cursor = cur;
    lines[cur.line].text = left + right;
    lines[cur.anchorLine].text =
        lines[cur.anchorLine].text.substring(cur.anchorColumn);
    for (int i = 0; i < res.length - 1; i++) {
      lines.removeAt(cur.line + 1);
    }
    General.validateCursor(lines, cursor, false);
  }

  static void clearSelection(Cursor cursor) {
    cursor.anchorLine = cursor.line;
    cursor.anchorColumn = cursor.column;
  }

  static void deleteText(List<TextLine> lines, Cursor cursor,
      {int numberOfCharacters = 1}) {
    deleteRegular(numberOfCharacters, lines, cursor);
  }

  static void deleteRegular(
      int numberOfCharacters, List<TextLine> lines, Cursor cursor) {
    String l = lines[cursor.line].text;

    // handle join lines
    if (cursor.column >= l.length) {
      Cursor cur = cursor.copy();
      lines[cursor.line].text += lines[cursor.line + 1].text;
      CursorCommands.moveCursorDown(lines, cursor);
      deleteLine(lines, cursor);
      cursor = cur;
      return;
    }
    Cursor cur = cursor.normalized();

    String left = l.substring(0, cur.column);
    String right = l.substring(cur.column + numberOfCharacters);
    cursor = cur;

    if (lines[cursor.line].lineStyles != null) {
      lines[cursor.line].lineStyles!.removeWhere(
            (element) => left.isEmpty ? true : element.anchor >= left.length,
          );
    }

    // handle erase entire line
    if (lines.length > 1 && (left + right).isEmpty) {
      lines.removeAt(cur.line);
      CursorCommands.moveCursorUp(lines, cursor, keepAnchor: false);
      CursorCommands.moveCursorToStartOfLine(lines, cursor, keepAnchor: false);
      return;
    }

    lines[cursor.line].text = left + right;
  }

  static List<String> selectedLines(List<TextLine> lines, Cursor cursor) {
    List<String> res = <String>[];
    Cursor cur = cursor.normalized();
    if (lines.isEmpty) return [];

    if (cur.line == cur.anchorLine) {
      String sel = lines[cur.line].text.substring(cur.column, cur.anchorColumn);
      res.add(sel);
      return res;
    }

    res.add(lines[cur.line].text.substring(cur.column));
    for (int i = cur.line + 1; i < cur.anchorLine; i++) {
      res.add(lines[i].text);
    }
    res.add(lines[cur.anchorLine].text.substring(0, cur.anchorColumn));
    return res;
  }

  static String selectedText(List<TextLine> lines, Cursor cursor) {
    return selectedLines(lines, cursor).join('\n');
  }

  static deleteLine(List<TextLine> lines, Cursor cursor,
      {int numberOfLines = 1}) {
    for (int i = 0; i < numberOfLines; i++) {
      CursorCommands.moveCursorToStartOfLine(lines, cursor, keepAnchor: false);
      deleteText(lines, cursor,
          numberOfCharacters: lines[cursor.line].text.length);
    }
    validateCursor(lines, cursor, false);
  }

  static List<String> selectAll(List<TextLine> lines, Cursor cursor) {
    List<String> res = <String>[];
    Cursor cur = cursor.normalized();

    res.add(lines[cur.line].text.substring(cur.column));
    for (int i = cur.line + 1; i < cur.anchorLine; i++) {
      res.add(lines[i].text);
    }
    res.add(lines[cur.anchorLine].text.substring(0, cur.anchorColumn));

    CursorCommands.moveCursorToStartOfDocument(lines, cursor, keepAnchor: true);
    validateCursor(lines, cursor, true);
    return res;
  }

  static void validateCursor(
      List<TextLine> lines, Cursor cursor, bool keepAnchor) {
    if (cursor.line >= lines.length) {
      cursor.line = lines.length - 1;
    }
    if (cursor.line < 0) cursor.line = 0;
    if (cursor.column > lines[cursor.line].text.length &&
        lines[cursor.line].type == 1) {
      cursor.column = lines[cursor.line].text.length;
    }
    if (cursor.column == -1) cursor.column = lines[cursor.line].text.length;
    if (cursor.column < 0) cursor.column = 0;
    if (!keepAnchor) {
      cursor.anchorLine = cursor.line;
      cursor.anchorColumn = cursor.column;
    }

    Document.observer
        ?.getObserver('line_number_size_updated', lines[cursor.line].size);
  }
}

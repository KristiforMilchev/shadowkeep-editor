import 'dart:io';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:shadowkeep_editor/text_line.dart';

class Cursor {
  Cursor({
    this.line = 0,
    this.column = 0,
    this.anchorLine = 0,
    this.anchorColumn = 0,
    this.cursorLineWordIndex = 0,
  });

  int line = 0;
  int column = 0;
  int anchorLine = 0;
  int anchorColumn = 0;

  int cursorLineWordIndex;

  Cursor copy() {
    return Cursor(
      line: line,
      column: column,
      anchorLine: anchorLine,
      anchorColumn: anchorColumn,
    );
  }

  Cursor normalized() {
    Cursor res = copy();
    if (line > anchorLine || (line == anchorLine && column > anchorColumn)) {
      res.line = anchorLine;
      res.column = anchorColumn;
      res.anchorLine = line;
      res.anchorColumn = column;
      return res;
    }
    return res;
  }

  bool hasSelection() {
    return line != anchorLine || column != anchorColumn;
  }
}

class Document {
  String docPath = '';
  List<TextLine> lines = <TextLine>[];
  Cursor cursor = Cursor();
  String clipboardText = '';

  Future<bool> openFile(String path) async {
    lines = <TextLine>[];
    docPath = path;
    File f = File(docPath);
    await f.openRead().map(utf8.decode).transform(const LineSplitter()).forEach(
      (l) {
        insertText(l);
        insertNewLine();
      },
    );
    moveCursorToStartOfDocument();
    return true;
  }

  Future<bool> saveFile({String? path}) async {
    File f = File(path ?? docPath);
    String content = '';
    for (var l in lines) {
      content += l.text + '\n';
    }
    f.writeAsString(content);
    return true;
  }

  void _validateCursor(bool keepAnchor) {
    if (cursor.line >= lines.length) {
      cursor.line = lines.length - 1;
    }
    if (cursor.line < 0) cursor.line = 0;
    if (cursor.column > lines[cursor.line].text.length) {
      cursor.column = lines[cursor.line].text.length;
    }
    if (cursor.column == -1) cursor.column = lines[cursor.line].text.length;
    if (cursor.column < 0) cursor.column = 0;
    if (!keepAnchor) {
      cursor.anchorLine = cursor.line;
      cursor.anchorColumn = cursor.column;
    }
  }

  void moveCursor(int line, int column, {bool keepAnchor = false}) {
    cursor.line = line;
    cursor.column = column;
    _validateCursor(keepAnchor);
  }

  void moveCursorLeft({int count = 1, bool keepAnchor = false}) {
    cursor.column = cursor.column - count;
    if (cursor.column < 0) {
      moveCursorUp(keepAnchor: keepAnchor);
      moveCursorToEndOfLine(keepAnchor: keepAnchor);
    }
    _validateCursor(keepAnchor);
  }

  void moveCursorRight({int count = 1, bool keepAnchor = false}) {
    cursor.column = cursor.column + count;
    if (cursor.column > lines[cursor.line].text.length) {
      moveCursorDown(keepAnchor: keepAnchor);
      moveCursorToStartOfLine(keepAnchor: keepAnchor);
    }
    _validateCursor(keepAnchor);
  }

  void moveCursorUp({int count = 1, bool keepAnchor = false}) {
    cursor.line = cursor.line - count;
    _validateCursor(keepAnchor);
  }

  void moveCursorDown({int count = 1, bool keepAnchor = false}) {
    cursor.line = cursor.line + count;
    _validateCursor(keepAnchor);
  }

  void moveCursorToStartOfLine({bool keepAnchor = false}) {
    cursor.column = 0;
    _validateCursor(keepAnchor);
  }

  void moveCursorToEndOfLine({bool keepAnchor = false}) {
    cursor.column = lines[cursor.line].text.length;
    _validateCursor(keepAnchor);
  }

  void moveCursorToStartOfDocument({bool keepAnchor = false}) {
    cursor.line = 0;
    cursor.column = 0;
    _validateCursor(keepAnchor);
  }

  void moveCursorToEndOfDocument({bool keepAnchor = false}) {
    cursor.line = lines.length - 1;
    cursor.column = lines[cursor.line].text.length;
    _validateCursor(keepAnchor);
  }

  void insertNewLine() {
    deleteSelectedText();
    insertText('\n');
  }

  void insertText(String text) {
    deleteSelectedText();

    if (lines.elementAtOrNull(cursor.line) == null) {
      createLineAtCursor();
    }

    String l = lines[cursor.line].text;
    String left = l.substring(0, cursor.column);
    String right = l.substring(cursor.column);

    // handle new line
    if (text == '\n') {
      lines[cursor.line].text = left;

      lines.insert(
        cursor.line + 1,
        TextLine(
          text: right,
          type: 1,
          align: TextAlign.left,
          hasColor: false,
        ),
      );
      moveCursorDown();
      moveCursorToStartOfLine();
      return;
    }

    lines[cursor.line].text = left + text + right;
    moveCursorRight(count: text.length);
  }

  void deleteText({int numberOfCharacters = 1}) {
    String l = lines[cursor.line].text;

    // handle join lines
    if (cursor.column >= l.length) {
      Cursor cur = cursor.copy();
      lines[cursor.line].text += lines[cursor.line + 1].text;
      moveCursorDown();
      deleteLine();
      cursor = cur;
      return;
    }

    Cursor cur = cursor.normalized();
    String left = l.substring(0, cur.column);
    String right = l.substring(cur.column + numberOfCharacters);
    cursor = cur;

    // handle erase entire line
    if (lines.length > 1 && (left + right).isEmpty) {
      lines.removeAt(cur.line);
      moveCursorUp();
      moveCursorToStartOfLine();
      return;
    }

    lines[cursor.line].text = left + right;
  }

  void deleteLine({int numberOfLines = 1}) {
    for (int i = 0; i < numberOfLines; i++) {
      moveCursorToStartOfLine();
      deleteText(numberOfCharacters: lines[cursor.line].text.length);
    }
    _validateCursor(false);
  }

  List<String> selectedLines() {
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

  String selectedText() {
    return selectedLines().join('\n');
  }

  void deleteSelectedText() {
    if (!cursor.hasSelection()) {
      return;
    }

    Cursor cur = cursor.normalized();
    List<String> res = selectedLines();
    if (res.length == 1) {
      print(cur.anchorColumn - cur.column);
      deleteText(numberOfCharacters: cur.anchorColumn - cur.column);
      clearSelection();
      return;
    }

    if (lines.elementAtOrNull(cur.line) == null) createLineAtCursor();

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
    _validateCursor(false);
  }

  void clearSelection() {
    cursor.anchorLine = cursor.line;
    cursor.anchorColumn = cursor.column;
  }

  void command(String cmd) {
    switch (cmd) {
      case 'ctrl+c':
        clipboardText = selectedText();
        break;
      case 'ctrl+x':
        clipboardText = selectedText();
        deleteSelectedText();
        break;
      case 'ctrl+v':
        insertText(clipboardText);
        break;
      case 'ctrl+s':
        saveFile();
        break;
    }
  }

  void moveCursorLeftMarkWord({required bool keepAnchor}) {
    var line = lines[cursor.line].text;
    var words = line
        .substring(0, cursor.anchorColumn)
        .split(' ')
        .where((element) => element.isNotEmpty)
        .toList();

    moveCursorLeft(
      count: words.last.length + 1,
      keepAnchor: keepAnchor,
    );
  }

  void moveCursorRightMarkWord({required bool keepAnchor}) {
    var line = lines[cursor.line].text;
    var words = line
        .substring(cursor.anchorColumn)
        .split(' ')
        .where((element) => element.isNotEmpty)
        .toList();

    moveCursorRight(
      count: words.first.length + 1,
      keepAnchor: keepAnchor,
    );
  }

  void centerElement({required bool keepAnchor}) {
    lines[cursor.line].align = lines[cursor.line].align == TextAlign.center
        ? TextAlign.left
        : TextAlign.center;

    _validateCursor(keepAnchor);
  }

  void createLineAtCursor() {
    lines.insert(
      cursor.line,
      TextLine(type: 1, align: TextAlign.start, hasColor: false),
    );
  }
}

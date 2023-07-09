import 'dart:io';
import 'dart:convert';
import 'package:domain/models/enums.dart';
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
  bool isList = false;

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

  void moveCursorLeftList(int count, bool keepAnchor) {
    cursor.column--;
    if (cursor.column >
        lines[cursor.line]
            .listLines![lines[cursor.line].lineNumber]
            .text
            .length) {
      moveCursorDown(keepAnchor: keepAnchor);
      moveCursorToStartOfLine(keepAnchor: keepAnchor);
    }
    _validateCursor(keepAnchor);
  }

  void moveCursorRightList({int count = 1, bool keepAnchor = false}) {
    cursor.column = cursor.column + count;

    print(cursor.column);
    if (cursor.column >
        lines[cursor.line]
            .listLines![lines[cursor.line].lineNumber]
            .text
            .length) {
      moveCursorDown(keepAnchor: keepAnchor);
      moveCursorToStartOfLine(keepAnchor: keepAnchor);
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
    insertStandard(text);
  }

  insertStandard(String text) {
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
          type: isList ? 2 : 1,
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

  insertInList(String text) {
    // handle new line

    String l =
        lines[cursor.line].listLines![lines[cursor.line].lineNumber].text;
    String left = l.substring(0, cursor.column);
    String right = l.substring(cursor.column);

    if (text == '\n') {
      lines[cursor.line].listLines![lines[cursor.line].lineNumber].text = left;

      lines[cursor.line].listLines!.insert(
            lines[cursor.line].lineNumber + 1,
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

    lines[cursor.line].listLines![lines[cursor.line].lineNumber].text =
        left + text + right;
    moveCursorRightList(count: text.length);
  }

  void deleteText({int numberOfCharacters = 1}) {
    deleteRegular(numberOfCharacters);
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

  void executeFromUi(EditorCommand cmd) {
    switch (cmd) {
      case EditorCommand.copy:
        clipboardText = selectedText();
        break;
      case EditorCommand.cut:
        clipboardText = selectedText();
        deleteSelectedText();
        break;
      case EditorCommand.paste:
        insertText(clipboardText);
        break;
      case EditorCommand.save:
        saveFile();
        break;
      case EditorCommand.h1:
        convertToHeading(24, keepAnchor: true);
        break;
      case EditorCommand.h2:
        convertToHeading(19, keepAnchor: true);
        break;
      case EditorCommand.h3:
        convertToHeading(16, keepAnchor: true);
        break;
      case EditorCommand.bold:
        setBold(keepAnchor: true);
        break;
      case EditorCommand.alignCenter:
        setElementPosition(position: TextAlign.center, keepAnchor: false);
        break;
      case EditorCommand.alightRight:
        setElementPosition(position: TextAlign.end, keepAnchor: false);
        break;
      case EditorCommand.alightLeft:
        setElementPosition(position: TextAlign.start, keepAnchor: false);
        break;
      case EditorCommand.bulletList:
        createList();
        break;
      case EditorCommand.wrapDoubleQuoute:
        encapsulate(keepAnchor: true);
        break;
      case EditorCommand.selectAll:
        selectAll();
        break;

      case EditorCommand.delete:
        if (cursor.hasSelection()) {
          deleteText(numberOfCharacters: cursor.column + cursor.anchorColumn);
        } else {
          deleteLine();
        }
        break;
      case EditorCommand.undo:
      // TODO: Handle this case.
      case EditorCommand.redo:
      // TODO: Handle this case.
      case EditorCommand.orderedList:
      // TODO: Handle this case.
      case EditorCommand.wrapSingleQuoute:
      // TODO: Handle this case.
      case EditorCommand.underline:
      // TODO: Handle this case.
    }
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
      case 'ctrl+1':
        convertToHeading(24, keepAnchor: true);
        break;
      case 'ctrl+2':
        convertToHeading(19, keepAnchor: true);
        break;
      case 'ctrl+3':
        convertToHeading(16, keepAnchor: true);
        break;
      case 'ctrl+b':
        setBold(keepAnchor: true);
        break;
      case 'ctrl+k':
        setElementPosition(position: TextAlign.center, keepAnchor: false);
        break;
      case 'ctrl+l':
        setElementPosition(position: TextAlign.end, keepAnchor: false);
        break;
      case 'ctrl+j':
        setElementPosition(position: TextAlign.start, keepAnchor: false);
        break;
      case 'ctrl+[':
        createList();
        break;
      case 'ctrl+"':
        encapsulate(keepAnchor: true);
        break;
      case 'ctrl+a':
        selectAll();
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

  void setElementPosition(
      {required TextAlign position, required bool keepAnchor}) {
    lines[cursor.line].align =
        lines[cursor.line].align == position ? TextAlign.left : position;

    _validateCursor(keepAnchor);
  }

  void createLineAtCursor() {
    lines.insert(
      cursor.line,
      TextLine(type: 1, align: TextAlign.start, hasColor: false),
    );
  }

  void convertToHeading(int i, {required bool keepAnchor}) {
    lines[cursor.line].size = i;
    _validateCursor(keepAnchor);
  }

  void setBold({required bool keepAnchor}) {
    lines[cursor.line].isBold = !lines[cursor.line].isBold;
    _validateCursor(keepAnchor);
  }

  void skipParagraphUp({required bool keepAnchor}) {
    var currentList = lines.take(cursor.line).toList();
    var emptyLine =
        currentList.lastWhereOrNull((element) => element.text.isNotEmpty);
    if (emptyLine != null) {
      cursor.line = lines.indexOf(emptyLine);
    }
    _validateCursor(keepAnchor);
  }

  void skipParagraphDown({required bool keepAnchor}) {
    int index = lines.indexWhere(
        (element) =>
            element.text.isNotEmpty &&
            element.text != lines.elementAt(cursor.line).text,
        cursor.line);
    if (index != -1) {
      cursor.line = index;
    } else {
      cursor.line = cursor.line + 1;
    }
    _validateCursor(keepAnchor);
  }

  void createList() {
    if (!isList) {
      isList = true;
      lines.insert(
        cursor.line,
        TextLine(
          type: 2,
          align: TextAlign.start,
          hasColor: false,
        ),
      );
    } else {
      isList = false;
    }
  }

  void deleteRegular(int numberOfCharacters) {
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

  void encapsulate({required bool keepAnchor}) {
    if (!cursor.hasSelection()) {
      checkQuoutesLine();
      return;
    }

    checkQuoutesSelection();
  }

  void checkQuoutesLine() {
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

  void checkQuoutesSelection() {
    if (!cursor.hasSelection()) return;

    var left = lines[cursor.line].text.substring(0, cursor.column);
    var right = lines[cursor.line]
        .text
        .substring(cursor.anchorColumn, lines[cursor.line].text.length);
    var quouteContent =
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

  void selectAll() {
    cursor.anchorLine = lines.length;
    cursor.anchorColumn = lines.last.text.length;
    cursor.column = 0;

    moveCursorToStartOfDocument(keepAnchor: true);
    _validateCursor(true);
  }
}

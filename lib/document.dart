import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:domain/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:infrastructure/interfaces/iobserver.dart';
import 'package:shadowkeep_editor/cursor.dart';
import 'package:shadowkeep_editor/editor_commands/cursor_commands.dart';
import 'package:shadowkeep_editor/editor_commands/general.dart';
import 'package:shadowkeep_editor/editor_commands/quoutes.dart';
import 'package:shadowkeep_editor/editor_commands/bold.dart';
import 'package:shadowkeep_editor/editor_commands/underline.dart';
import 'package:shadowkeep_editor/history.dart';
import 'package:shadowkeep_editor/text_line.dart';

class Document {
  GetIt getIt = GetIt.I;
  static IObserver? observer;

  String docPath = '';
  List<TextLine> lines = <TextLine>[];
  Cursor cursor = Cursor();
  String clipboardText = '';
  bool isList = false;
  String _activeFont = 'FiraCode';
  String get activeFont => _activeFont;
  GlobalKey cursorKey = GlobalKey();

  int historyIndex = 0;

  Document() {
    observer = getIt.get<IObserver>();
  }

  newFile() {
    lines = <TextLine>[];

    insertText('');
  }

  Future<bool> openFile(String path) async {
    lines = <TextLine>[];
    docPath = path;
    File f = File(docPath);

    var openFile = f.openRead();
    var lenght = await openFile.length;
    if (lenght > 0) {
      openFile.map(utf8.decode).transform(const LineSplitter()).forEach(
        (l) {
          insertText(l);
          insertNewLine();
        },
      );
    } else {
      insertText("test");
    }

    CursorCommands.moveCursorToStartOfDocument(lines, cursor);
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

  void moveCursor(int line, int column, {bool keepAnchor = false}) {
    cursor.line = line;
    cursor.column = column;
    General.validateCursor(lines, cursor, keepAnchor);
  }

  void insertNewLine() {
    General.deleteSelectedText(lines, cursor);

    insertText('\n');
  }

  void insertText(String text) {
    General.deleteSelectedText(lines, cursor);

    if (lines.elementAtOrNull(cursor.line) == null) {
      CursorCommands.createLineAtCursor(lines, cursor);
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
          lineStyles: [],
        ),
      );

      CursorCommands.moveCursorDown(lines, cursor);
      CursorCommands.moveCursorToStartOfLine(lines, cursor);
      return;
    }

    History.addToHistory(lines.toList());
    lines[cursor.line].text = left + text + right;
    CursorCommands.moveCursorRight(lines, cursor, count: text.length);
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
      CursorCommands.moveCursorDown(lines, cursor);
      CursorCommands.moveCursorToStartOfLine(lines, cursor);
      return;
    }

    lines[cursor.line].listLines![lines[cursor.line].lineNumber].text =
        left + text + right;
    CursorCommands.moveCursorRightList(lines, cursor, count: text.length);
  }

  void executeFromUi(EditorCommand cmd) {
    switch (cmd) {
      case EditorCommand.copy:
        clipboardText = General.selectedText(lines, cursor);
        break;
      case EditorCommand.cut:
        clipboardText = General.selectedText(lines, cursor);
        General.deleteSelectedText(lines, cursor);
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
        Bold.apply(lines, cursor);
        General.validateCursor(lines, cursor, true);
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
        Quoutes.apply(cursor, lines);
        break;
      case EditorCommand.selectAll:
        General.selectAll(lines, cursor);
        break;
      case EditorCommand.delete:
        if (cursor.hasSelection()) {
          General.deleteText(lines, cursor,
              numberOfCharacters: cursor.column + cursor.anchorColumn);
        } else {
          General.deleteLine(lines, cursor);
        }
        break;
      case EditorCommand.increaseFont:
        increaseEditorFont();
        break;
      case EditorCommand.decreseFont:
        decreaseEditorFont();
        break;
      case EditorCommand.underline:
        Underline.apply(lines, cursor);
        break;
      case EditorCommand.undo:
        var getUndo = History.undo();
        if (getUndo == null) return;

        lines = getUndo;
        break;
      case EditorCommand.redo:
        var getRedo = History.redo();
        if (getRedo == null) return;

        lines = getRedo;
        break;
      case EditorCommand.orderedList:
      // TODO: Handle this case.
      case EditorCommand.wrapSingleQuoute:
      // TODO: Handle this case.
    }
  }

  void command(String cmd) {
    switch (cmd) {
      case 'ctrl+c':
        clipboardText = General.selectedText(lines, cursor);
        break;
      case 'ctrl+x':
        clipboardText = General.selectedText(lines, cursor);
        General.deleteSelectedText(lines, cursor);
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
        Bold.apply(lines, cursor);
        General.validateCursor(lines, cursor, true);
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
        Quoutes.apply(cursor, lines);
        break;
      case 'ctrl+a':
        General.selectAll(lines, cursor);
        break;
    }
  }

  void setElementPosition(
      {required TextAlign position, required bool keepAnchor}) {
    lines[cursor.line].align =
        lines[cursor.line].align == position ? TextAlign.left : position;
    General.validateCursor(lines, cursor, keepAnchor);
  }

  void convertToHeading(int i, {required bool keepAnchor}) {
    lines[cursor.line].size = i;

    General.validateCursor(lines, cursor, keepAnchor);
  }

  void skipParagraphUp({required bool keepAnchor}) {
    var currentList = lines.take(cursor.line).toList();
    var emptyLine =
        currentList.lastWhereOrNull((element) => element.text.isNotEmpty);
    if (emptyLine != null) {
      cursor.line = lines.indexOf(emptyLine);
    }
    General.validateCursor(lines, cursor, keepAnchor);
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
    General.validateCursor(lines, cursor, keepAnchor);
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

  void increaseEditorFont() {
    lines[cursor.line].size = lines[cursor.line].size + 1;
    observer?.getObserver('line_number_size_updated', lines[cursor.line].size);
  }

  void decreaseEditorFont() {
    if (lines[cursor.line].size < 1) return;

    lines[cursor.line].size = lines[cursor.line].size - 1;
    observer?.getObserver('line_number_size_updated', lines[cursor.line].size);
  }

  onFontFamilyChanged(String fontName) {
    _activeFont = fontName;
  }
}

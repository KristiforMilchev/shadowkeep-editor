import 'package:shadowkeep_editor/cursor.dart';
import 'package:shadowkeep_editor/text_line.dart';

class Underline {
  static apply(List<TextLine> lines, Cursor cursor) {
    if (cursor.hasSelection()) {
      applySelection(lines, cursor);
      return;
    }

    lines[cursor.line].isUnderlined = !lines[cursor.line].isUnderlined;
  }

  static void applySelection(List<TextLine> lines, Cursor cursor) {
    throw Exception("Not implemented");
  }
}

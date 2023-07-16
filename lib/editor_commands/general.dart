import 'package:shadowkeep_editor/document.dart';
import 'package:shadowkeep_editor/text_line.dart';

class General {
  static ensureInitialized(List<TextLine> lines, Cursor cursor) {
    if (lines[cursor.line].lineStyles == null) {
      lines[cursor.line].lineStyles = [];
    }
  }
}

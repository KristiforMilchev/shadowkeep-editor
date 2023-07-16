import 'package:shadowkeep_editor/document.dart';
import 'package:shadowkeep_editor/editor_commands/general.dart';
import 'package:shadowkeep_editor/text_line.dart';
import 'package:shadowkeep_editor/text_line_styles.dart';

class Bold {
  static apply(List<TextLine> lines, Cursor cursor) {
    if (!cursor.hasSelection()) {
      lines[cursor.line].isBold = !lines[cursor.line].isBold;
      return;
    }

    General.ensureInitialized(lines, cursor);

    var start = cursor.column > cursor.anchorColumn
        ? cursor.anchorColumn
        : cursor.column;
    var end = cursor.column > cursor.anchorColumn
        ? cursor.column
        : cursor.anchorColumn;

    lines[cursor.line].lineStyles!.forEach((element) {
      print('Existing styles ${element.column}, ${element.anchor}');
    });

    if (lines[cursor.line].lineStyles!.any((element) =>
        element.isBold && element.column >= start && element.anchor <= end)) {
      lines[cursor.line].lineStyles!.removeWhere(
            (element) =>
                element.isBold &&
                element.column >= start &&
                element.anchor <= end,
          );

      return;
    }

    lines[cursor.line].lineStyles?.add(TextLineStyles(
          anchor: end - 1,
          column: start,
          isBold: true,
        ));
  }
}

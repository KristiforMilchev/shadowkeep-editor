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

    // if (lines[cursor.line].lineStyles!.any(
    //       (element) =>
    //           element.isBold &&
    //           element.column == cursor.column &&
    //           element.anchor <= cursor.anchorColumn,
    //     )) {
    //   lines[cursor.line].lineStyles!.removeWhere((element) => element.isBold);
    //   return;
    // }

    if (lines[cursor.line].lineStyles!.any((element) =>
        element.isBold &&
        element.column == cursor.column &&
        element.anchor >= cursor.anchorColumn)) {
      lines[cursor.line]
          .lineStyles!
          .where((element) =>
              element.isBold &&
              element.column == cursor.column &&
              element.anchor >= cursor.anchorColumn)
          .forEach((e) {
        lines[cursor.line].lineStyles!.remove(e);
      });
      return;
    }

    lines[cursor.line].lineStyles?.add(TextLineStyles(
          hasColor: null,
          anchor: cursor.anchorColumn,
          column: cursor.column,
          isBold: true,
          isUnderlined: false,
        ));
  }
}

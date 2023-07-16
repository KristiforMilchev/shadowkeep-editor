import 'package:flutter/material.dart';
import 'package:shadowkeep_editor/text_line.dart';
import 'dart:collection';
import 'dart:ui' as ui;

import 'document.dart';

double fontSize = 18;
double gutterFontSize = 16;

Size getTextExtents(String text, TextStyle style) {
  final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr)
    ..layout(minWidth: 0, maxWidth: double.infinity);
  return textPainter.size;
}

Color foreground = const Color(0xfff8f8f2);
Color background = const Color(0xff272822);
Color selection = const Color(0xff44475a);

class LineDecoration {
  int start = 0;
  int end = 0;
  Color color = Colors.white;
  Color background = Colors.white;
  bool underline = false;
  bool italic = false;
}

class CustomWidgetSpan extends WidgetSpan {
  final int line;
  const CustomWidgetSpan({required Widget child, this.line = 0})
      : super(child: child);
}

class Highlighter {
  HashMap<String, Color> colorMap = HashMap<String, Color>();

  Highlighter() {
    colorMap.clear();
  }

  List<InlineSpan> run(
      String text, int line, Document document, TextLine? textLine) {
    double size = 14;
    FontWeight weight = FontWeight.normal;
    Cursor cur = document.cursor.normalized();
    if (textLine != null) {
      size = textLine.size.toDouble();
      weight = textLine.isBold && !cur.hasSelection()
          ? FontWeight.bold
          : FontWeight.normal;
    }

    TextStyle defaultStyle = TextStyle(
      fontFamily: document.activeFont,
      fontSize: size,
      color: foreground,
      fontWeight: weight,
    );

    List<InlineSpan> res = <InlineSpan>[];

    text += ' ';
    String prevText = '';
    for (int i = 0; i < text.length; i++) {
      String ch = text[i];
      TextStyle style = defaultStyle.copyWith();

      // is within selection true. outside of the selection
      // False inside the selection

      if (textLine!.lineStyles != null) {
        var matchingStyles = textLine.lineStyles!
            .any((element) => element.anchor >= i && element.column <= i);
        if (matchingStyles) {
          var apply = textLine.lineStyles!
              .where((element) => element.anchor >= i && element.column <= i);
          for (var currentStyle in apply) {
            style = style.copyWith(
              decoration: currentStyle.isUnderlined
                  ? TextDecoration.underline
                  : style.decoration,
              fontWeight:
                  currentStyle.isBold ? FontWeight.bold : style.fontWeight,
            );
          }
        }
      }

      if (cur.hasSelection()) {
        if (line < cur.line ||
            (line == cur.line && i < cur.column) ||
            line > cur.anchorLine ||
            (line == cur.anchorLine && i + 1 > cur.anchorColumn)) {
          style = style.copyWith(color: Colors.red);
        } else {
          style = style.copyWith(
              backgroundColor: selection.withOpacity(0.75),
              decoration:
                  textLine.isUnderlined ? TextDecoration.underline : null,
              fontWeight:
                  textLine.isBold ? FontWeight.bold : FontWeight.normal);
        }
      }

      // Cursor style
      if ((line == document.cursor.line && i == document.cursor.column)) {
        res.add(
          WidgetSpan(
            alignment: ui.PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    width: 1.5,
                    color: Colors.red,
                  ),
                ),
              ),
              child: Text(
                ch,
                style: style.copyWith(letterSpacing: -1.5),
              ),
            ),
          ),
        );
        continue;
      }

      if (res.isNotEmpty && res[res.length - 1] is! WidgetSpan) {
        TextSpan prev = res[res.length - 1] as TextSpan;
        if (prev.style == style) {
          prevText += ch;
          res[res.length - 1] = TextSpan(
            text: prevText,
            style: style,
            mouseCursor: MaterialStateMouseCursor.textable,
          );
          continue;
        }
      }

      res.add(
        TextSpan(
          text: ch,
          style: style,
          mouseCursor: MaterialStateMouseCursor.textable,
        ),
      );
      prevText = ch;
    }

    res.add(
      CustomWidgetSpan(child: const SizedBox(height: 1, width: 8), line: line),
    );

    return res;
  }
}

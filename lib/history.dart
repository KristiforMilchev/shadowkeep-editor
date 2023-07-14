import 'package:shadowkeep_editor/text_line.dart';

class History {
  static List<List<TextLine>> _history = [];
  static int historyIndex = 0;

  static List<TextLine>? undo() {
    if (historyIndex <= 0) return null;
    historyIndex = historyIndex - 1;
    print(historyIndex);
    return _history[historyIndex];
  }

  static List<TextLine>? redo() {
    if (historyIndex == _history.length) return null;
    historyIndex = historyIndex + 1;
    return _history[historyIndex];
  }

  static void addToHistory(List<TextLine> lines) {
    List<TextLine> current = [];
    lines.map((e) {
      TextLine line = TextLine(
        type: e.type,
        align: e.align,
        hasColor: e.hasColor,
        text: e.text,
      );
      current.add(line);
    }).toList();
    if (_history.length > 25000) {
      _history.remove(_history.first);
    }

    _history.add(current);

    historyIndex = _history.length;
  }
}

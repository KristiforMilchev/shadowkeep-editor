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

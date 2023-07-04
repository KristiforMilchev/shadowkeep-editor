import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadowkeep_editor/text_line.dart';

import 'document.dart';
import 'highlighter.dart';

class DocumentProvider extends ChangeNotifier {
  Document doc = Document();

  Future<bool> openFile(String path) async {
    bool res = await doc.openFile(path);
    touch();
    return res;
  }

  void touch() {
    notifyListeners();
  }
}

class ViewLine extends StatelessWidget {
  const ViewLine({this.lineNumber = 0, this.textLine, super.key});

  final int lineNumber;
  final TextLine? textLine;

  @override
  Widget build(BuildContext context) {
    DocumentProvider doc = Provider.of<DocumentProvider>(context);
    Highlighter hl = Provider.of<Highlighter>(context);
    List<InlineSpan> spans = hl.run(
      textLine != null ? textLine!.text : '',
      lineNumber,
      doc.doc,
      textLine,
    );

    if (textLine?.type == 1) {
      return Container(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: RichText(
          text: TextSpan(children: spans),
          softWrap: true,
          textAlign: textLine != null ? textLine!.align : TextAlign.left,
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...textLine!.listLines!.map((e) {
              List<InlineSpan> spans = hl.run(
                e.text,
                lineNumber,
                doc.doc,
                e,
              );

              return Container(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: RichText(
                  text: TextSpan(children: spans),
                  softWrap: true,
                  textAlign: e.align,
                ),
              );
            })
          ],
        ),
      );
    }
  }
}

class EditorView extends StatefulWidget {
  const EditorView({super.key, this.path = ''});
  final String path;

  @override
  _EditorView createState() => _EditorView();
}

class _EditorView extends State<EditorView> {
  late ScrollController scroller;

  @override
  void initState() {
    scroller = ScrollController();
    super.initState();
  }

  @override
  void dispose() {
    scroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DocumentProvider doc = Provider.of<DocumentProvider>(context);
    return ListView.builder(
        controller: scroller,
        itemCount: doc.doc.lines.length,
        itemBuilder: (BuildContext context, int index) {
          return ViewLine(lineNumber: index, textLine: doc.doc.lines[index]);
        });
  }
}

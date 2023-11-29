import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:domain/models/intellisense_data.dart';

import 'editor_view.dart';
import 'input.dart';
import 'highlighter.dart';

class Editor extends StatefulWidget {
  final List<IntellisenseData> intellisenseData;
  final String path;
  final Color? fontColor;

  const Editor({
    super.key,
    this.path = '',
    required this.intellisenseData,
    this.fontColor,
  });
  @override
  _Editor createState() => _Editor();
}

class _Editor extends State<Editor> {
  late DocumentProvider doc;
  @override
  void initState() {
    doc = DocumentProvider();
    doc.setIntellisenseData(widget.intellisenseData);
    if (widget.path.isNotEmpty) doc.openFile(widget.path);
    if (widget.path.isEmpty) doc.startNewFile();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => doc),
        Provider(create: (context) => Highlighter())
      ],
      child: const InputListener(
        child: EditorView(),
      ),
    );
  }
}

void main() async {
  ThemeData themeData = ThemeData(
    fontFamily: 'FiraCode',
    primaryColor: foreground,
    backgroundColor: background,
    scaffoldBackgroundColor: background,
  );
  return runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeData,
      home: const Scaffold(
        body: Editor(path: './tests/tinywl.c', intellisenseData: []),
      ),
    ),
  );
}

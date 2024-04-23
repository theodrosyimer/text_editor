import 'package:appflowy_editor/appflowy_editor.dart';
// ignore: implementation_imports
import 'package:appflowy_editor/src/editor/editor_component/service/shortcuts/command/copy_paste_extension.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:text_editor/api/chat_api.dart';


final CommandShortcutEvent rephraseCommand = CommandShortcutEvent(
  key: 'rephrase the content',
  getDescription: () => Intl.message(
      'rephrase content',
      name: 'cmdRephraseContent',
      desc: '',
      args: [],
    ),
  command: 'ctrl+shift+e',
  macOSCommand: 'cmd+shift+e',
  handler: _rephraseCommandHandler,
);

CommandShortcutEventHandler _rephraseCommandHandler = (editorState) {
  final selection = editorState.selection;
  if (selection == null) {
    return KeyEventResult.ignored;
  }

  () async {
    final data = await AppFlowyClipboard.getData();
    final text = data.text;
    final html = data.html;

    final chatApi = ChatApi();
    final summary = await chatApi.assistantChat(
      chatInstruction: 'You will rephrase a given text. You should be very cautious to stay on topic. You should avoid repetitive content. You should try to generate the same amount of content as the original.',
      userInput: text!,
      );

    if (summary.content.toString().isEmpty) {
      return;
    }

    if (html != null && html.isNotEmpty) {
      await editorState.deleteSelectionIfNeeded();
      // if the html is pasted successfully, then return
      // otherwise, paste the plain text
      if (await editorState.pasteHtml(summary.content?[0].text ?? '')) {
        return;
      }
    }

    if (text.isNotEmpty) {
      await editorState.deleteSelectionIfNeeded();
      editorState.pastePlainText(summary.content.toString());
    }
  }();

  return KeyEventResult.handled;
};



RegExp _hrefRegex = RegExp(
  r'https?://(?:www\.)?[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,}(?:/[^\s]*)?',
);

extension on EditorState {
  Future<bool> pasteHtml(String html) async {
    final nodes = htmlToDocument(html).root.children.toList();
    // remove the front and back empty line
    while (nodes.isNotEmpty && nodes.first.delta?.isEmpty == true) {
      nodes.removeAt(0);
    }
    while (nodes.isNotEmpty && nodes.last.delta?.isEmpty == true) {
      nodes.removeLast();
    }
    if (nodes.isEmpty) {
      return false;
    }
    if (nodes.length == 1) {
      await pasteSingleLineNode(nodes.first);
    } else {
      await pasteMultiLineNodes(nodes.toList());
    }
    return true;
  }

  Future<void> pastePlainText(String plainText) async {
    if (await pasteHtmlIfAvailable(plainText)) {
      return;
    }

    await deleteSelectionIfNeeded();

    final nodes = plainText
        .split('\n')
        .map(
          (paragraph) => paragraph
            ..replaceAll(r'\r', '')
            ..trimRight(),
        )
        .map((paragraph) {
          Delta delta = Delta();
          if (_hrefRegex.hasMatch(paragraph)) {
            final firstMatch = _hrefRegex.firstMatch(paragraph);
            if (firstMatch != null) {
              int startPos = firstMatch.start;
              int endPos = firstMatch.end;
              final String? url = firstMatch.group(0);
              if (url != null) {
                /// insert the text before the link
                if (startPos > 0) {
                  delta.insert(paragraph.substring(0, startPos));
                }

                /// insert the link
                delta.insert(
                  paragraph.substring(startPos, endPos),
                  attributes: {AppFlowyRichTextKeys.href: url},
                );

                /// insert the text after the link
                if (endPos < paragraph.length) {
                  delta.insert(paragraph.substring(endPos));
                }
              }
            }
          } else {
            delta.insert(paragraph);
          }
          return delta;
        })
        .map((paragraph) => paragraphNode(delta: paragraph))
        .toList();

    if (nodes.isEmpty) {
      return;
    }
    if (nodes.length == 1) {
      await pasteSingleLineNode(nodes.first);
    } else {
      await pasteMultiLineNodes(nodes.toList());
    }
  }

  Future<bool> pasteHtmlIfAvailable(String plainText) async {
    final selection = this.selection;
    if (selection == null ||
        !selection.isSingle ||
        selection.isCollapsed ||
        !_hrefRegex.hasMatch(plainText)) {
      return false;
    }

    final node = getNodeAtPath(selection.start.path);
    if (node == null) {
      return false;
    }

    final transaction = this.transaction;
    transaction.formatText(node, selection.startIndex, selection.length, {
      AppFlowyRichTextKeys.href: plainText,
    });
    await apply(transaction);
    return true;
  }
}


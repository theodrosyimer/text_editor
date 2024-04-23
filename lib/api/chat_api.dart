import 'package:dart_openai/dart_openai.dart';
import 'package:text_editor/env/env.dart';

class ChatApi {
  static const _model = 'gpt-3.5-turbo';


  ChatApi() {
    OpenAI.apiKey = Env.apiKey;
  }

  Future<OpenAIChatCompletionChoiceMessageModel> assistantChat(String textInput) async {
    final systemMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          'You will summarize a given text into the most informative summary.',
        ),
      ],
      role: OpenAIChatMessageRole.assistant,
    );

    final userMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          textInput,
        ),
        ],
          role: OpenAIChatMessageRole.user,
        );

    final requestMessages = [
      systemMessage,
      userMessage,
    ];


    final OpenAIChatCompletionModel chatCompletion = await OpenAI.instance.chat.create(
      model: _model,
      messages: requestMessages,
    );

    return chatCompletion.choices.first.message;
  }
}

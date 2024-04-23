import 'package:dart_openai/dart_openai.dart';
import 'package:text_editor/env/env.dart';

class ChatApi {
  static const _model = 'gpt-3.5-turbo';


  ChatApi() {
    OpenAI.apiKey = Env.apiKey;
    OpenAI.requestsTimeOut = const Duration(seconds: 60);
  }

  Future<OpenAIChatCompletionChoiceMessageModel> assistantChat({required String chatInstruction, required String userInput}) async {
    final systemMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          chatInstruction,
        ),
      ],
      role: OpenAIChatMessageRole.assistant,
    );

    final userMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          userInput,
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

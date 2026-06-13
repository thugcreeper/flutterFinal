import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class AiAssistantApi {
  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  String get _apiKey => dotenv.env['AI_API_KEY'] ?? '';

  Future<String?> sendMessage({
    required List<ChatMessage> messages,
    required String systemPrompt,
  }) async {
    if (_apiKey.isEmpty) {
      throw AiAssistantException('AI_API_KEY 未設定');
    }

    final uri = Uri.parse(_baseUrl);

    // 轉成 OpenAI 格式
    final contents = [
      {'role': 'system', 'content': systemPrompt},
      ...messages.map(
        (m) => {
          'role': m.role == 'model' ? 'assistant' : 'user',
          'content': m.content,
        },
      ),
    ];

    final body = jsonEncode({
      'model': 'openai/gpt-oss-120b:free',
      'messages': contents,
      'max_tokens': 1024,
      'temperature': 0.7,
    });

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
            'HTTP-Referer': 'ridevoyage.app', // OpenRouter 要求
            'X-Title': 'RideVoyage',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 429) {
      throw AiAssistantException('已超過使用額度，請稍後再試', statusCode: 429);
    }
    if (response.statusCode != 200) {
      throw AiAssistantException(
        '請求失敗：${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw AiAssistantException('AI 未回傳任何結果');
    }

    final message = choices.first['message'] as Map<String, dynamic>?;
    return message?['content']?.toString();
  }
}

class AiAssistantException implements Exception {
  final String message;
  final int? statusCode;

  AiAssistantException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

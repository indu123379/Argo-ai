import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: 'YOUR_GROQ_API_KEY');
  final endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  final model = 'llama-3.3-70b-versatile'; // Testing flagship model

  print('Testing model: $model');
  try {
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': [{'role': 'user', 'content': 'Hello'}],
      }),
    );

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}

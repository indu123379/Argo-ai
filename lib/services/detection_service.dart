// lib/services/detection_service.dart
// Uses Groq API for ALL AI tasks:
//   • Vision (disease + crop id) → meta-llama/llama-4-scout-17b-16e-instruct
//   • AgroBot chat              → llama-3.1-8b-instant

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/detection_result.dart';

class DetectionService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Groq Configuration ────────────────────────────────────────────────────
  static const String _groqApiKey = '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';
  static const String _groqEndpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  // Vision model
  static const String _visionModel = 'llama-3.2-11b-vision-preview';
  // Flagship model for high-quality chat
  static const String _chatModel = 'llama-3.3-70b-versatile';

  bool _isAnalyzing = false;
  DetectionResult? _lastResult;
  String _status = '';

  bool get isAnalyzing => _isAnalyzing;
  DetectionResult? get lastResult => _lastResult;
  String get status => _status;

  // ─── Main analysis pipeline ───────────────────────────────────────────────
  Future<DetectionResult?> analyzeImage(
      Uint8List imageBytes, String cropType) async {
    _isAnalyzing = true;
    _status = 'Running AI analysis…';
    notifyListeners();

    try {
      String imageUrl = ''; // Skip upload for speed

      // 2. Call Groq vision model
      final analysisJson = await _callGroqVision(imageBytes, cropType);

      _status = 'Saving result…';
      notifyListeners();

      // 3. Build result object
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final resultId = const Uuid().v4();
      final result = DetectionResult(
        id: resultId,
        userId: uid,
        cropType: analysisJson['cropType'] ?? cropType,
        diseaseName: analysisJson['diseaseName'] ?? 'Unknown',
        severity: analysisJson['severity'] ?? 'low',
        confidenceScore: (analysisJson['confidenceScore'] ?? 0.0).toDouble(),
        severityPercent: (analysisJson['severityPercent'] ?? 0.0).toDouble(),
        imageUrl: imageUrl,
        description: analysisJson['description'] ?? '',
        symptoms: List<String>.from(analysisJson['symptoms'] ?? []),
        treatments: List<String>.from(analysisJson['treatments'] ?? []),
        preventions: List<String>.from(analysisJson['preventions'] ?? []),
        weatherNote: analysisJson['weatherNote'] ?? '',
        detectedAt: DateTime.now(),
      );

      // 4. Save to Firestore — MUST succeed for persistence
      debugPrint('Saving detection $resultId to Firestore for user $uid...');
      await _db
          .collection('detections')
          .doc(result.id)
          .set(result.toFirestore());
      debugPrint('Detection saved successfully!');

      if (uid != 'anonymous') {
        try {
          await _db.collection('farmers').doc(uid).update({
            'totalScans': FieldValue.increment(1),
          });
        } catch (e) {
          debugPrint('Could not update totalScans: $e');
        }
      }

      _lastResult = result;
      _isAnalyzing = false;
      _status = '';
      notifyListeners();
      return result;
    } catch (e) {
      _isAnalyzing = false;
      _status = 'Error: $e';
      debugPrint('analyzeImage error: $e');
      notifyListeners();
      rethrow;
    }
  }

  // ─── Identify crop only (Groq vision) ────────────────────────────────────
  Future<String> identifyCrop(Uint8List bytes) async {
    try {
      if (_groqApiKey.isEmpty) return 'Unknown';
      final b64 = base64Encode(bytes);
      final response = await http.post(
        Uri.parse(_groqEndpoint),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode(<String, dynamic>{
          'model': _visionModel,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text':
                      'Identify the crop in this image. Respond with ONLY the crop name (e.g. Rice, Tomato, Wheat). If not a crop, say "Unknown".',
                },
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$b64'},
                },
              ],
            }
          ],
          'max_tokens': 20,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text =
            data['choices']?[0]?['message']?['content'] as String? ?? '';
        return text.trim().isEmpty ? 'Unknown' : text.trim();
      } else {
        debugPrint('identifyCrop Groq error ${response.statusCode}: ${response.body}');
        return 'Unknown';
      }
    } catch (e) {
      debugPrint('identifyCrop error: $e');
      return 'Unknown';
    }
  }

  // ─── Call Groq Vision for disease analysis ────────────────────────────────
  Future<Map<String, dynamic>> _callGroqVision(
      Uint8List bytes, String cropType) async {
    final b64 = base64Encode(bytes);
    debugPrint('Groq vision request: for crop $cropType, b64 length ${b64.length}');

    final prompt = '''
Analyze this crop leaf image for diseases.
${cropType != 'Auto-detect' ? 'The crop type is: $cropType.' : 'First identify the crop.'}

Respond ONLY with a valid JSON object (no markdown fences) with exactly these fields:
{
  "cropType": "string",
  "diseaseName": "string (e.g. 'Rice Blast' or 'Healthy')",
  "severity": "low or moderate or high or critical",
  "confidenceScore": number between 0 and 1,
  "severityPercent": number between 0 and 100,
  "description": "2-3 sentences about the disease",
  "symptoms": ["string", "string"],
  "treatments": ["string", "string"],
  "preventions": ["string", "string"],
  "weatherNote": "string"
}''';

    if (_groqApiKey.isEmpty) {
      throw Exception('Groq API Key is missing in the configuration.');
    }

    try {
      final response = await http.post(
        Uri.parse(_groqEndpoint),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode(<String, dynamic>{
          'model': _visionModel,
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': prompt},
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$b64'},
                },
              ],
            }
          ],
          'max_tokens': 1024,
          'temperature': 0.1,
        }),
      );

      debugPrint('Groq vision response: ${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrint('Groq vision error body: ${response.body}');
        throw Exception('Groq vision error ${response.statusCode}: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final text = data['choices']?[0]?['message']?['content'] as String? ?? '{}';
      debugPrint('Groq vision text: $text');

      // Strip markdown fences if any
      final clean = text.replaceAll(RegExp(r'```json|```'), '').trim();
      return jsonDecode(clean) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error in _callGroqVision: $e');
      rethrow;
    }
  }

  // ─── AgroBot Chatbot via Groq API ─────────────────────────────────────────
  Future<String> askFarmingAssistant(
      String question, List<Map<String, String>> history) async {
    try {
      final List<Map<String, dynamic>> messages = [
        {
          'role': 'system',
          'content':
              '''You are "AgroBot", a world-class AI agricultural expert and friendly companion for farmers. 
Your goal is to provide perfectly accurate, practical, and highly detailed agricultural advice.

Guidelines:
1. **Accuracy**: Use the latest scientific knowledge for crop diseases, organic/chemical treatments, and soil health.
2. **Context**: Focus on Indian agricultural conditions (monsoons, soil types, regional crops) unless asked otherwise.
3. **Structured Responses**: Use bullet points and clear sections for treatments and preventions.
4. **Tone**: Be encouraging, respectful (address as "Farmer" or "Mitra"), and professional.
5. **Government Schemes**: Be knowledgeable about PM-KISAN, PMFBY, and other farmer welfare schemes.
6. **Clarity**: Explain complex terms. If you don't know something for sure, advise consulting a local KVK (Krishi Vigyan Kendra) expert.

Format your response using Markdown for better readability (bolding, lists).''',
        },
        ...history.map((m) => <String, dynamic>{
              'role': m['role'] == 'user' ? 'user' : 'assistant',
              'content': m['content'] ?? '',
            }),
        <String, dynamic>{'role': 'user', 'content': question},
      ];

      if (_groqApiKey.isEmpty) {
        return 'AgroBot configuration error: API Key is missing.';
      }

      final response = await http.post(
        Uri.parse(_groqEndpoint),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode(<String, dynamic>{
          'model': _chatModel,
          'messages': messages,
          'max_tokens': 1024,
          'temperature': 0.6,
        }),
      );

      debugPrint('Groq chat status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content =
            data['choices']?[0]?['message']?['content'] as String? ?? '';
        return content.trim().isEmpty
            ? 'Sorry, I could not generate a response.'
            : content.trim();
      } else {
        final err = jsonDecode(response.body)['error']?['message'] ?? 'Unknown Error';
        debugPrint('Groq API error ${response.statusCode}: ${response.body}');
        return 'AgroBot is temporarily unavailable. (Reason: $err)';
      }

    } catch (e) {
      debugPrint('Groq Chat Error: $e');
      return 'Encountered an issue with AI connectivity. Error: $e';
    }
  }

  // ─── Fetch history from Firestore ─────────────────────────────────────────
  Stream<List<DetectionResult>> historyStream(String userId) {
    return _db
        .collection('detections')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final results =
          snap.docs.map((d) => DetectionResult.fromFirestore(d)).toList();
      // Sort client-side (avoids needing a Firestore composite index)
      results.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
      return results;
    });
  }
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/app_config.dart';
import '../models/quiz_model.dart';
import '../models/question_model.dart';

/// Result returned by [GeminiService.generateQuiz].
class GeneratedQuizResult {
  final String title;
  final String? description;
  final String? category;
  final List<GeneratedQuestion> questions;

  GeneratedQuizResult({
    required this.title,
    this.description,
    this.category,
    required this.questions,
  });
}

class GeneratedQuestion {
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final bool isFlashcard;
  final String? flashcardBack;

  GeneratedQuestion({
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    required this.isFlashcard,
    this.flashcardBack,
  });
}

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: AppConfig.geminiModel,
      apiKey: AppConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.4,
      ),
    );
  }

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Extract readable text from file bytes depending on [extension].
  /// Returns null if extraction fails or format is unsupported.
  Future<String?> extractText(
    Uint8List bytes,
    String extension,
  ) async {
    switch (extension.toLowerCase()) {
      case 'txt':
        return utf8.decode(bytes, allowMalformed: true);
      case 'docx':
        return _extractDocxText(bytes);
      case 'pdf':
        // PDFs are sent as inline bytes directly to Gemini — return null here.
        return null;
      default:
        return utf8.decode(bytes, allowMalformed: true);
    }
  }

  /// Generate a quiz from [fileBytes].
  /// [fileName] is used to determine MIME type.
  /// [questionCount] controls how many questions to ask for (default 10).
  Future<GeneratedQuizResult> generateQuiz({
    required Uint8List fileBytes,
    required String fileName,
    int questionCount = 10,
  }) async {
    final ext = fileName.split('.').last.toLowerCase();
    final prompt = _buildPrompt(questionCount);

    List<Part> parts;

    if (ext == 'pdf') {
      // Send PDF bytes directly — Gemini understands PDFs natively.
      parts = [
        DataPart('application/pdf', fileBytes),
        TextPart(prompt),
      ];
    } else {
      // For TXT / DOCX extract text first.
      final text = await extractText(fileBytes, ext);
      if (text == null || text.trim().isEmpty) {
        throw Exception(
          'Could not extract text from the file. '
          'Try saving it as a PDF or plain text.',
        );
      }
      parts = [TextPart('$prompt\n\nDOCUMENT CONTENT:\n$text')];
    }

    final response = await _model.generateContent([Content.multi(parts)]);
    final raw = response.text;
    if (raw == null || raw.isEmpty) {
      throw Exception('Gemini returned an empty response. Please try again.');
    }

    return _parseResponse(raw);
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  String _buildPrompt(int count) => '''
You are an expert educational quiz generator.
Analyse the provided document and create $count questions.
Use roughly 70% multiple-choice and 30% flashcard questions.

Return ONLY valid JSON matching this exact schema — no markdown, no explanation:

{
  "quiz_title": "<concise title derived from the content>",
  "quiz_description": "<one-sentence description>",
  "quiz_category": "<subject area>",
  "questions": [
    {
      "type": "mcq",
      "question": "...",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correct_answer_index": 0,
      "explanation": "..."
    },
    {
      "type": "flashcard",
      "question": "...",
      "answer": "..."
    }
  ]
}''';

  GeneratedQuizResult _parseResponse(String raw) {
    // Strip any accidental markdown fences.
    final cleaned = raw
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    final Map<String, dynamic> json =
        jsonDecode(cleaned) as Map<String, dynamic>;

    final rawQuestions = (json['questions'] as List<dynamic>);
    final questions = rawQuestions.map((q) {
      final map = q as Map<String, dynamic>;
      final type = map['type'] as String? ?? 'mcq';
      if (type == 'flashcard') {
        return GeneratedQuestion(
          questionText: map['question'] as String,
          options: [map['answer'] as String],
          correctAnswerIndex: 0,
          isFlashcard: true,
          flashcardBack: map['answer'] as String,
        );
      } else {
        final opts = (map['options'] as List<dynamic>)
            .map((o) => o.toString())
            .toList();
        return GeneratedQuestion(
          questionText: map['question'] as String,
          options: opts,
          correctAnswerIndex: (map['correct_answer_index'] as int?) ?? 0,
          isFlashcard: false,
        );
      }
    }).toList();

    return GeneratedQuizResult(
      title: json['quiz_title'] as String? ?? 'AI Generated Quiz',
      description: json['quiz_description'] as String?,
      category: json['quiz_category'] as String?,
      questions: questions,
    );
  }

  /// Extract plain text from a DOCX file (which is a ZIP of XML files).
  static String _extractDocxText(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final wordDoc = archive.findFile('word/document.xml');
      if (wordDoc == null) return '';
      final xml = utf8.decode(wordDoc.content as List<int>);
      // Extract text between <w:t> tags.
      final matches = RegExp(r'<w:t[^>]*>(.*?)</w:t>').allMatches(xml);
      return matches.map((m) => m.group(1) ?? '').join(' ');
    } catch (_) {
      return '';
    }
  }

  /// Convert a [GeneratedQuizResult] into domain models ready to save.
  static (QuizModel, List<QuestionModel>) toModels(
    GeneratedQuizResult result,
    String userId,
    String quizId,
  ) {
    final now = DateTime.now();
    final questions = result.questions.asMap().entries.map((e) {
      final GeneratedQuestion q = e.value;
      final qId = '${quizId}_q${e.key}';
      return QuestionModel(
        id: qId,
        quizId: quizId,
        questionText: q.questionText,
        options: q.options,
        correctAnswerIndex: q.correctAnswerIndex,
        isFlashcard: q.isFlashcard,
        flashcardBack: q.flashcardBack,
        createdAt: now,
      );
    }).toList();

    final quiz = QuizModel(
      id: quizId,
      userId: userId,
      title: result.title,
      description: result.description,
      category: result.category,
      questionIds: questions.map((q) => q.id).toList(),
      createdAt: now,
    );

    return (quiz, questions);
  }
}

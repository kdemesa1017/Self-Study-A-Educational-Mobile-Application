import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../config/app_config.dart';
import '../../services/gemini_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/connectivity_provider.dart';

class AiQuizGeneratorScreen extends ConsumerStatefulWidget {
  const AiQuizGeneratorScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AiQuizGeneratorScreen> createState() => _AiQuizGeneratorScreenState();
}

enum _GenerationState { initial, loading, success, error }

class _AiQuizGeneratorScreenState extends ConsumerState<AiQuizGeneratorScreen> with SingleTickerProviderStateMixin {
  PlatformFile? _selectedFile;
  double _questionCount = 10;
  _GenerationState _state = _GenerationState.initial;
  String _errorMessage = '';
  
  late final AnimationController _animationController;
  
  // To hold generated quiz models
  dynamic _generatedQuiz;
  dynamic _generatedQuestions;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'docx'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      
      // Check file size limit
      final maxBytes = AppConfig.maxUploadBytes;
      if (file.size > maxBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File exceeds the 20MB limit.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      setState(() {
        _selectedFile = file;
        _state = _GenerationState.initial;
      });
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _state = _GenerationState.initial;
    });
  }

  Future<void> _generateQuiz() async {
    final isOnline = ref.read(isOnlineProvider).valueOrNull ?? false;
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI generation requires internet connection'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedFile == null || _selectedFile!.bytes == null) return;

    setState(() {
      _state = _GenerationState.loading;
    });

    try {
      final fileBytes = _selectedFile!.bytes!;
      final fileName = _selectedFile!.name;
      final count = _questionCount.toInt();
      
      final result = await GeminiService().generateQuiz(
        fileBytes: fileBytes,
        fileName: fileName,
        questionCount: count,
      );

      final user = ref.read(currentUserProvider).valueOrNull;
      final userId = user?.id ?? 'anonymous';
      final quizId = const Uuid().v4();

      final (quiz, questions) = GeminiService.toModels(result, userId, quizId);

      setState(() {
        _generatedQuiz = quiz;
        _generatedQuestions = questions;
        _state = _GenerationState.success;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _state = _GenerationState.error;
      });
    }
  }

  Future<void> _saveAndOpenQuiz() async {
    if (_generatedQuiz == null || _generatedQuestions == null) return;

    final user = ref.read(currentUserProvider).valueOrNull;
    final userId = user?.id ?? 'anonymous';

    await ref.read(userQuizzesProvider(userId).notifier).saveGeneratedQuiz(
      _generatedQuiz,
      _generatedQuestions,
    );

    if (mounted) {
      context.go('/quiz/${_generatedQuiz.id}');
    }
  }

  Color _getFileTypeColor(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf': return Colors.redAccent;
      case 'txt': return Colors.blueAccent;
      case 'docx': return Colors.teal;
      default: return Colors.grey;
    }
  }

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildGlassCard(
          child: Column(
            children: [
              if (_selectedFile == null) ...[
                Icon(Icons.upload_file, size: 64, color: Colors.white.withOpacity(0.7)),
                const SizedBox(height: 16),
                const Text(
                  'Upload a document',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Supported formats: PDF, TXT, DOCX\nMax size: 20MB',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Browse Files'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _getFileTypeColor(_selectedFile!.extension ?? ''),
                      child: Text(
                        _selectedFile!.extension?.toUpperCase() ?? 'DOC',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedFile!.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _removeFile,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Number of Questions',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_questionCount.toInt()}',
                      style: const TextStyle(color: const Color(0xFF6C63FF), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: const Color(0xFF6C63FF),
                  inactiveTrackColor: Colors.white.withOpacity(0.2),
                  thumbColor: Colors.white,
                  overlayColor: const Color(0xFF6C63FF).withOpacity(0.2),
                ),
                child: Slider(
                  value: _questionCount,
                  min: 5,
                  max: 20,
                  divisions: 15,
                  onChanged: (val) {
                    setState(() => _questionCount = val);
                  },
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _selectedFile == null ? null : _generateQuiz,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              disabledBackgroundColor: Colors.white.withOpacity(0.1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text(
              'Generate Quiz',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: _buildGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: const [Color(0xFF6C63FF), Colors.purpleAccent, Color(0xFF6C63FF)],
                      stops: const [0.0, 0.5, 1.0],
                      transform: GradientRotation(_animationController.value * 2 * 3.14159),
                    ).createShader(bounds);
                  },
                  child: const Icon(Icons.auto_awesome, size: 80, color: Colors.white),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'AI is reading your document...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'This might take a minute depending on the document size.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: _buildGlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 24),
            const Text(
              'Oops! Something went wrong.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() => _state = _GenerationState.initial);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    final title = _generatedQuiz?.title ?? 'Generated Quiz';
    final qCount = _generatedQuestions?.length ?? _questionCount.toInt();
    
    return Center(
      child: _buildGlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 48, color: Colors.greenAccent),
            ),
            const SizedBox(height: 24),
            const Text(
              'Quiz Ready!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$qCount Questions Generated',
                    style: const TextStyle(
                      color: const Color(0xFF6C63FF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveAndOpenQuiz,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Save & Open Quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('AI Quiz Generator', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E), // Deep Purple
              Color(0xFF16213E), // Indigo
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: switch (_state) {
                _GenerationState.initial => _buildInitialState(),
                _GenerationState.loading => _buildLoadingState(),
                _GenerationState.success => _buildSuccessState(),
                _GenerationState.error => _buildErrorState(),
              },
            ),
          ),
        ),
      ),
    );
  }
}

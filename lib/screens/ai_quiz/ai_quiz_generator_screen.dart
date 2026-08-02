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
  const AiQuizGeneratorScreen({super.key});

  @override
  ConsumerState<AiQuizGeneratorScreen> createState() => _AiQuizGeneratorScreenState();
}

enum _GenerationState { initial, loading, success, error }

class _AiQuizGeneratorScreenState extends ConsumerState<AiQuizGeneratorScreen> with SingleTickerProviderStateMixin {
  PlatformFile? _selectedFile;
  double _questionCount = 10;
  String _difficulty = 'Medium';
  final TextEditingController _instructionController = TextEditingController();
  _GenerationState _state = _GenerationState.initial;
  String _errorMessage = '';
  
  // Question types to include in generation
  final Set<String> _selectedTypes = {'mcq', 'flashcard', 'identification', 'enumeration'};

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
    _instructionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'docx', 'pptx', 'ppt'],
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
    final isOnline = await ref.read(connectivityServiceProvider).isOnline;
    if (!isOnline) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI generation requires internet connection'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        difficulty: _difficulty,
        selectedTypes: _selectedTypes.toList(),
        customInstruction: _instructionController.text.trim().isEmpty
            ? null
            : _instructionController.text.trim(),
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
      case 'pptx':
      case 'ppt': return Colors.orangeAccent;
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
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGlassCard(
            child: Column(
              children: [
                if (_selectedFile == null) ...[
                  Icon(Icons.upload_file, size: 64, color: Colors.white.withValues(alpha: 0.7)),
                  const SizedBox(height: 16),
                  const Text(
                    'Upload a document',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Supported formats: PDF, TXT, DOCX, PPTX\nMax size: 20MB',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
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
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
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
          const SizedBox(height: 16),
          // Question Count Card
          _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Number of Questions (1-50)',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_questionCount.toInt()}',
                        style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: const Color(0xFF6C63FF),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                    thumbColor: Colors.white,
                    overlayColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: _questionCount,
                    min: 5,
                    max: 50,
                    divisions: 45,
                    onChanged: (val) {
                      setState(() => _questionCount = val);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Difficulty Level Card
          _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Difficulty Level',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Easy', 'Medium', 'High', 'Extreme'].map((level) {
                      final isSelected = _difficulty == level;
                      Color chipColor;
                      switch (level) {
                        case 'Easy': chipColor = Colors.green; break;
                        case 'Medium': chipColor = Colors.blue; break;
                        case 'High': chipColor = Colors.orange; break;
                        case 'Extreme': chipColor = Colors.red; break;
                        default: chipColor = const Color(0xFF6C63FF);
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(level),
                          selected: isSelected,
                          selectedColor: chipColor,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _difficulty = level);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Chatbox / AI Instructions Card
          _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: Colors.white70, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'AI Instructions / Chatbox (Optional)',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _instructionController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g., Focus on Chapter 2, include dates, prioritize definitions...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Question Types Card
          _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Question Types to Include',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select at least one type',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTypeChip('mcq', 'Multiple Choice', Icons.list_alt_rounded, Colors.blue),
                    _buildTypeChip('flashcard', 'Flashcard', Icons.flip_rounded, Colors.orange),
                    _buildTypeChip('identification', 'Identification', Icons.edit_note_rounded, Colors.teal),
                    _buildTypeChip('enumeration', 'Enumeration', Icons.format_list_numbered_rounded, Colors.purple),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: (_selectedFile == null || _selectedTypes.isEmpty) ? null : _generateQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
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
      ),
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon, Color color) {
    final isSelected = _selectedTypes.contains(type);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            // Don't allow deselecting if it's the last one
            if (_selectedTypes.length > 1) {
              _selectedTypes.remove(type);
            }
          } else {
            _selectedTypes.add(type);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_box_rounded : icon,
              color: isSelected ? color : Colors.white54,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
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
                color: Colors.white.withValues(alpha: 0.6),
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
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
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
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
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
                color: Colors.greenAccent.withValues(alpha: 0.2),
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
                color: Colors.white.withValues(alpha: 0.05),
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
                      color: Color(0xFF6C63FF),
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

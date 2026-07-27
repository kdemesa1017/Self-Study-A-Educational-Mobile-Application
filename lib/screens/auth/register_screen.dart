import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  int _currentStep = 1;
  bool _isLoading = false;

  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();

  // Step 1 Controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _schoolController = TextEditingController();
  String? _selectedGrade;

  // Step 2 Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final List<String> _gradeLevels = [
    'Grade 7',
    'Grade 8',
    'Grade 9',
    'Grade 10',
    'Grade 11',
    'Grade 12',
    '1st Year College',
    '2nd Year College',
    '3rd Year College',
    '4th Year College',
    'Graduate',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _schoolController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_formKeyStep1.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      setState(() {
        _currentStep = 2;
      });
    }
  }

  void _previousStep() {
    FocusScope.of(context).unfocus();
    setState(() {
      _currentStep = 1;
    });
  }

  Future<void> _submit() async {
    if (_formKeyStep2.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      setState(() {
        _isLoading = true;
      });

      int? age = int.tryParse(_ageController.text.trim());
      String school = _schoolController.text.trim();

      final error = await ref.read(currentUserProvider.notifier).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            age: age,
            school: school.isEmpty ? null : school,
            gradeLevel: _selectedGrade,
          );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.redAccent,
            ),
          );
        } else {
          // Navigate to home or dashboard after success
          context.go('/');
        }
      }
    }
  }

  // Password Strength Logic
  int _passwordStrength = 0; // 0: None, 1: Weak, 2: Fair, 3: Strong
  Color _strengthColor = Colors.transparent;

  void _checkPasswordStrength(String pwd) {
    if (pwd.isEmpty) {
      setState(() {
        _passwordStrength = 0;
        _strengthColor = Colors.transparent;
      });
      return;
    }

    if (pwd.length < 8) {
      setState(() {
        _passwordStrength = 1;
        _strengthColor = Colors.redAccent;
      });
      return;
    }

    bool hasUpper = pwd.contains(RegExp(r'[A-Z]'));
    bool hasLower = pwd.contains(RegExp(r'[a-z]'));
    bool hasDigit = pwd.contains(RegExp(r'\d'));
    bool hasSpecial = pwd.contains(RegExp(r'[!@#\$%\^&\*(),.?":{}|<>]'));

    int mixCount = (hasUpper ? 1 : 0) +
        (hasLower ? 1 : 0) +
        (hasDigit ? 1 : 0) +
        (hasSpecial ? 1 : 0);

    if (mixCount == 4) {
      setState(() {
        _passwordStrength = 3;
        _strengthColor = Colors.green;
      });
    } else if (mixCount >= 2) {
      setState(() {
        _passwordStrength = 2;
        _strengthColor = Colors.orangeAccent;
      });
    } else {
      setState(() {
        _passwordStrength = 1;
        _strengthColor = Colors.redAccent;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE6E6FA), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        final inAnimation = Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(animation);
                        final outAnimation = Tween<Offset>(
                          begin: const Offset(-1.0, 0.0),
                          end: Offset.zero,
                        ).animate(animation);

                        return SlideTransition(
                          position: child.key == ValueKey(_currentStep)
                              ? inAnimation
                              : outAnimation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: _currentStep == 1
                          ? _buildStep1(key: const ValueKey(1))
                          : _buildStep2(key: const ValueKey(2)),
                    ),
                  ),
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          const Text(
            'Create Account',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepDot(1),
              Container(
                width: 40,
                height: 2,
                color: _currentStep == 2
                    ? const Color(0xFF6C63FF)
                    : Colors.grey.shade300,
              ),
              _buildStepDot(2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step) {
    bool isActive = _currentStep >= step;
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? const Color(0xFF6C63FF) : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextButton(
        onPressed: () => context.go('/login'),
        child: const Text(
          'Already have an account? Sign In',
          style: TextStyle(
            color: Color(0xFF6C63FF),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildStep1({Key? key}) {
    return _buildGlassCard(
      child: Form(
        key: _formKeyStep1,
        child: Column(
          key: key,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Personal Info',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              maxLength: 60,
              decoration: _inputDecoration('Full Name', Icons.person),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Full Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _inputDecoration('Age (Optional)', Icons.cake),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  int? age = int.tryParse(value);
                  if (age == null || age < 10 || age > 100) {
                    return 'Please enter a valid age (10-100)';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _schoolController,
              maxLength: 80,
              decoration: _inputDecoration(
                  'School/Institution (Optional)', Icons.school),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedGrade,
              decoration:
                  _inputDecoration('Grade/Year Level (Optional)', Icons.book),
              items: _gradeLevels.map((grade) {
                return DropdownMenuItem(
                  value: grade,
                  child: Text(grade),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGrade = value;
                });
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _nextStep,
              style: _primaryButtonStyle(),
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2({Key? key}) {
    return _buildGlassCard(
      child: Form(
        key: _formKeyStep2,
        child: Column(
          key: key,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Account Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration('Email', Icons.email),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value)) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: _inputDecoration('Password', Icons.lock),
              onChanged: _checkPasswordStrength,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                if (value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            _buildPasswordStrengthIndicator(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: _inputDecoration('Confirm Password', Icons.lock_outline),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _previousStep,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF6C63FF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(color: Color(0xFF6C63FF)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: _primaryButtonStyle(),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Sign Up'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    if (_passwordStrength == 0) return const SizedBox.shrink();

    String label;
    switch (_passwordStrength) {
      case 1:
        label = 'Weak';
        break;
      case 2:
        label = 'Fair';
        break;
      case 3:
        label = 'Strong';
        break;
      default:
        label = '';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (index) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 2 ? 8.0 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: index < _passwordStrength
                      ? _strengthColor
                      : Colors.grey.shade300,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          'Password Strength: $label',
          style: TextStyle(
            color: _strengthColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF6C63FF),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

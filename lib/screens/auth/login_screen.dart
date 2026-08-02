import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _showResultModal(
    String title,
    String message,
    bool isSuccess, {
    VoidCallback? onDismiss,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      isSuccess
                          ? [Colors.green.shade50, Colors.white]
                          : [Colors.red.shade50, Colors.white],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors:
                            isSuccess
                                ? [Colors.green, Colors.green.shade600]
                                : [Colors.red, Colors.red.shade600],
                      ),
                    ),
                    child: Icon(
                      isSuccess ? Icons.check_rounded : Icons.close_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          isSuccess
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (onDismiss != null) onDismiss();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSuccess ? Colors.green : Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final error = await ref
          .read(currentUserProvider.notifier)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (error != null) {
        _showResultModal(
          'Login Failed',
          error.replaceAll('Exception: ', ''),
          false,
        );
      } else {
        _showResultModal(
          'Welcome Back!',
          'You have successfully logged in.',
          true,
          onDismiss: () {
            if (mounted) context.go('/');
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showResultModal(
        'Error',
        'Something went wrong. Please try again.',
        false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const primaryColor = Color(0xFF5C4EE8);
    const bgColor = Color(0xFFF0EFFF);

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Decorative blobs ───────────────────────────────────────
          Positioned(
            top: -60,
            right: -60,
            child: _Blob(
              size: 200,
              color: primaryColor.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            top: 60,
            right: 20,
            child: _DotGrid(color: primaryColor.withValues(alpha: 0.18)),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: _Blob(
              size: 240,
              color: primaryColor.withValues(alpha: 0.08),
            ),
          ),

          // ── Main content ───────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: size.height * 0.02,
              ),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.25),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            'assets/images/Logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Self ',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                              TextSpan(
                                text: 'Study',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'LEARN  •  GROW  •  EXPLORE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Welcome text
                        const Text(
                          'Welcome! 👋',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to continue your learning journey',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Glass Card ──────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.07),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(24),
                          child: AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Email field
                                const Text(
                                  'Email',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [
                                    AutofillHints.username,
                                    AutofillHints.email,
                                  ],
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    hintText: 'Enter your email',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 14,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: primaryColor,
                                      size: 20,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF8F8FF),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: primaryColor,
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Password field
                                const Text(
                                  'Password',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  autofillHints: const [AutofillHints.password],
                                  enableSuggestions: false,
                                  autocorrect: false,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted:
                                      (_) => _isLoading ? null : _login(),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your password',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 14,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: primaryColor,
                                      size: 20,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: Colors.grey.shade500,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(
                                        () =>
                                            _obscurePassword = !_obscurePassword,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF8F8FF),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: primaryColor,
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Remember me + Forgot password
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged:
                                            (v) => setState(
                                              () => _rememberMe = v ?? false,
                                            ),
                                        activeColor: primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Remember me',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Forgot Password — Coming Soon!',
                                            ),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'Forgot password?',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Sign In Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 4,
                                      shadowColor: primaryColor.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                    child:
                                        _isLoading
                                            ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                            : const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.login_rounded,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Sign In',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Divider
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: Colors.grey.shade300,
                                        thickness: 1,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        'or continue with',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: Colors.grey.shade300,
                                        thickness: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Google Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Google Sign-In — Coming Soon!',
                                          ),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Google "G" logo using colored segments
                                        _GoogleIcon(),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Google',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Sign Up link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account?",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => context.push('/register'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: primaryColor,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                      ),
                                      child: const Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Feature Row ─────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _FeatureTile(
                              icon: Icons.style_rounded,
                              iconBg: const Color(0xFF7C6FF7),
                              label: 'Smart Flashcards',
                              sub: 'Flip & memorize faster',
                            ),
                            _FeatureTile(
                              icon: Icons.auto_awesome_rounded,
                              iconBg: const Color(0xFFFF8C42),
                              label: 'AI Quiz Generator',
                              sub: 'Upload docs & generate',
                            ),
                            _FeatureTile(
                              icon: Icons.quiz_rounded,
                              iconBg: const Color(0xFF4CAF50),
                              label: 'Quiz Modes',
                              sub: 'MCQ, ID & Enumeration',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper Widgets ─────────────────────────────────────────────────────────────

class _Blob extends StatelessWidget {
  final double size;
  final Color color;

  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _DotGrid extends StatelessWidget {
  final Color color;
  const _DotGrid({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemCount: 25,
        itemBuilder:
            (context, index) => Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String label;
  final String sub;

  const _FeatureTile({
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: iconBg.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Renders a Google "G" logo purely via a CustomPainter — no image assets needed.
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _GooglePainter(),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final paint = Paint()..style = PaintingStyle.fill;

    // Draw the four colored arcs of the Google "G"
    // We simulate by drawing a circle ring and painting quadrants
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Blue - top right
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -1.57, 1.57, true, paint);

    // Red - top left
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -3.14, 1.57, true, paint);

    // Yellow - bottom left
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 1.57, 1.57, true, paint);

    // Green - bottom right
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0, 1.57, true, paint);

    // White center hole
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.6, paint);

    // White "G" notch on right side
    paint.color = const Color(0xFF4285F4);
    final gRect = Rect.fromLTWH(cx, cy - r * 0.18, r, r * 0.36);
    canvas.drawRect(gRect, paint);

    // Inner white again for clean look
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.55, paint);
  }

  @override
  bool shouldRepaint(_GooglePainter oldDelegate) => false;
}

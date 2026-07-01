import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tripsync/core/utils/snackbar_helper.dart';
import 'package:tripsync/features/auth/data/services/auth_service.dart';
import 'package:tripsync/features/auth/presentation/widgets/auth_hero.dart';
import 'dart:ui';

import 'package:tripsync/features/auth/presentation/widgets/register_form.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister(
    String fullName,
    String email,
    String password,
  ) async {
    try {
      setState(() => _isLoading = true);

      final response = await _authService.signUp(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user != null) {
        await _authService.createProfile(
          userId: user.id,
          fullName: fullName,
          email: email,
        );

        if (mounted) {
          SnackbarHelper.showSuccess(
            context,
            'حساب کاربری شما با موفقیت ایجاد شد',
          );
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'خطا در ایجاد حساب کاربری',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // background image with error fallback
            Image.asset(
              'assets/images/TravelBg.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, _, _) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1a6fa8), Color(0xFF0d3b6e)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Gradient overlay
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.10),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Content
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 24,
                ),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 60),
                          const AuthHero(),
                          const SizedBox(height: 40),
                          RegisterForm(
                            onRegister: _handleRegister,
                            isLoading: _isLoading,
                          ),
                          const SizedBox(height: 20),
                          _buildLoginButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Login button
  Widget _buildLoginButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.30),
              width: 1.5,
            ),
          ),
          child: TextButton(
            onPressed: () {
              context.pop();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontFamily: 'Vazirmatn',
                ),
                children: [
                  TextSpan(text: 'حساب دارید؟  '),
                  TextSpan(
                    text: 'ورود',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      decorationColor: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

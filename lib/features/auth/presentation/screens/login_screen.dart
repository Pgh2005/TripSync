import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tripsync/core/theme/app_colors.dart';
import 'dart:ui';

import 'package:tripsync/features/auth/presentation/widgets/login_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
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

  void _handleLogin(String email, String password) async {
    setState(() => _isLoading = true);
    // await supabase.auth.signInWithPassword(email: email, password: password);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          title: const Text(
            'ورود به حساب کاربری',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              shadows: [Shadow(color: Colors.black38, blurRadius: 6)],
            ),
          ),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // background image
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

            // gradient layer on background for reliable in reading
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeroSection(),
                          const SizedBox(height: 36),
                          LoginForm(
                            onLogin: _handleLogin,
                            isLoading: _isLoading,
                          ),
                          const SizedBox(height: 20),
                          _buildRegisterButton(),
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

  // Hero Section with logo and tagline
  Widget _buildHeroSection() {
    return Column(
      children: [
        Image.asset(
          'assets/images/TripSyncLogo.png',
          width: 140,
          height: 140,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(
            Icons.travel_explore_rounded,
            color: Colors.white,
            size: 80,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              color: AppColors.primaryColor,
              size: 18,
            ),
            SizedBox(width: 10),
            const Text(
              'همراه سفرهای گروهی شما',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.taglineColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  // Register button
  Widget _buildRegisterButton() {
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
              context.push('/register');
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
                  TextSpan(text: 'حساب ندارید؟  '),
                  TextSpan(
                    text: 'ثبت نام',
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

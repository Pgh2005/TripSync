import 'package:flutter/material.dart';
import 'package:tripsync/core/theme/app_colors.dart';
import 'dart:ui';
import 'auth_text_field.dart';

class RegisterForm extends StatefulWidget {
  final void Function(String fullName, String email, String password)
  onRegister;
  final bool isLoading;

  const RegisterForm({
    super.key,
    required this.onRegister,
    required this.isLoading,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onRegister(
        _fullNameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.30),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Fullname
                AuthTextField(
                  controller: _fullNameController,
                  label: 'نام و نام خانوادگی',
                  labelIcon: Icons.person_outline_rounded,
                  hint: 'علی محمدی',
                  suffixIcon: Icons.badge_outlined,
                  keyboardType: TextInputType.name,
                  isRtl: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'نام نمی‌تواند خالی باشد';
                    }
                    if (value.trim().length < 3) {
                      return 'نام باید حداقل ۳ کاراکتر باشد';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Email
                AuthTextField(
                  controller: _emailController,
                  label: 'ایمیل',
                  labelIcon: Icons.email_outlined,
                  hint: 'example@email.com',
                  suffixIcon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'ایمیل نمی‌تواند خالی باشد';
                    }
                    if (!RegExp(
                      r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'ایمیل معتبر نیست';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Password
                AuthTextField(
                  controller: _passwordController,
                  label: 'رمز عبور',
                  labelIcon: Icons.lock_outline_rounded,
                  hint: '••••••••',
                  suffixIcon: Icons.key_rounded,
                  obscureText: _obscurePassword,
                  prefixIconWidget: GestureDetector(
                    onTap: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        key: ValueKey(_obscurePassword),
                        color: Colors.white60,
                        size: 20,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'رمز عبور نمی‌تواند خالی باشد';
                    }
                    if (value.length < 6) {
                      return 'رمز عبور باید حداقل ۶ کاراکتر باشد';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Password Confirmation
                AuthTextField(
                  controller: _confirmPasswordController,
                  label: 'تکرار رمز عبور',
                  labelIcon: Icons.lock_outline_rounded,
                  hint: '••••••••',
                  suffixIcon: Icons.key_rounded,
                  obscureText: _obscureConfirm,
                  prefixIconWidget: GestureDetector(
                    onTap: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        key: ValueKey(_obscureConfirm),
                        color: Colors.white60,
                        size: 20,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'تکرار رمز عبور نمی‌تواند خالی باشد';
                    }
                    if (value != _passwordController.text) {
                      return 'رمز عبور و تکرار آن یکسان نیستند';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 28),

                // Register button
                _buildRegisterButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 20, 136, 138),
            AppColors.authPrimaryColor.withValues(alpha: 0.5),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.authPrimaryColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: widget.isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: widget.isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'ثبت نام',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.person_add_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
      ),
    );
  }
}

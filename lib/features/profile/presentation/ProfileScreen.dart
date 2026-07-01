import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripsync/core/theme/app_colors.dart';
import 'package:tripsync/core/utils/snackbar_helper.dart';
import 'package:tripsync/features/auth/data/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  final AuthService _authService = AuthService();

  String _fullName = '';
  String _email = '';
  bool _isLoading = true;
  bool _hasProfileError = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _loadProfile();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasProfileError = false;
      });
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        context.go('/login');
        return;
      }

      final profile = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _email = user.email ?? '';
        _fullName = (profile?['full_name'] as String?)?.trim() ?? '';
      });
    } catch (e) {
      debugPrint('Load profile error: $e');

      if (!mounted) return;

      setState(() => _hasProfileError = true);

      SnackbarHelper.showError(context, 'خطا در دریافت اطلاعات پروفایل: $e');
    } finally {
      if (!mounted) return;

      setState(() => _isLoading = false);
      _animController.forward();
    }
  }

  Future<void> _refreshProfile() async {
    await _loadProfile();
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await _showLogoutDialog();

    if (shouldLogout != true) return;
    if (!mounted) return;

    setState(() => _isLoggingOut = true);

    try {
      await _authService.signOut();

      if (!mounted) return;
      context.go('/login');
    } catch (e) {
      debugPrint('Logout error: $e');

      if (!mounted) return;

      SnackbarHelper.showError(context, 'خطا در خروج از حساب: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  Future<bool?> _showLogoutDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.errorColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.errorColor,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'خروج از حساب',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'مطمئنی می‌خوای از حسابت خارج بشی؟',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => context.pop(false),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.borderColor,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'انصراف',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => context.pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.errorColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'خروج',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── initials از نام کامل ─────────────────────────────────────────
  String get _initials {
    if (_fullName.trim().isEmpty) return '?';
    final parts = _fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return parts[0][0];
  }

  String get _displayName =>
      _fullName.isNotEmpty ? _fullName : 'کاربر TripSync';

  void _showComingSoon(String feature) {
    SnackbarHelper.showInfo(context, '$feature به‌زودی اضافه می‌شود');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: RefreshIndicator(
          color: AppColors.primaryColor,
          onRefresh: _refreshProfile,
          child: _isLoading
              ? const CustomScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                )
              : CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // ── Hero Header ─────────────────────────────────
                    _buildHeroHeader(),

                    // ── محتوا ──────────────────────────────────────
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              20,
                              24,
                              20,
                              MediaQuery.of(context).padding.bottom + 32,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_hasProfileError) ...[
                                  _buildErrorBanner(),
                                  const SizedBox(height: 16),
                                ],

                                // اطلاعات حساب
                                _buildInfoCard(),
                                const SizedBox(height: 20),

                                // تنظیمات
                                _buildSettingsCard(),
                                const SizedBox(height: 28),

                                // دکمه خروج
                                _buildLogoutButton(),
                              ],
                            ),
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

  // ── Hero Header ──────────────────────────────────────────────────
  SliverAppBar _buildHeroHeader() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.primaryColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: _buildHeroBackground(),
      ),
    );
  }

  Widget _buildHeroBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryColor, Color(0xFF1D4ED8)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Stack(
        children: [
          // دایره‌های تزئینی
          Positioned(top: -40, left: -40, child: _decorCircle(180, 0.07)),
          Positioned(bottom: -60, right: -20, child: _decorCircle(200, 0.07)),
          Positioned(top: 80, left: 120, child: _decorCircle(60, 0.05)),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'پروفایل',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // آواتار + اسم + ایمیل
                  Column(
                    children: [
                      // آواتار بزرگ
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.40),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // نام کامل
                      Text(
                        _displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // ایمیل
                      Text(
                        _email.isNotEmpty ? _email : 'ایمیل ثبت نشده',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.74),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorColor.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.errorColor.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.errorColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.errorColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'اطلاعات پروفایل کامل دریافت نشد. برای تلاش دوباره صفحه را پایین بکش.',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── کارت اطلاعات حساب ───────────────────────────────────────────
  Widget _buildInfoCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('اطلاعات حساب', Icons.person_outline_rounded),
          const SizedBox(height: 16),

          _infoRow(
            icon: Icons.badge_outlined,
            iconColor: AppColors.primaryColor,
            iconBg: AppColors.primaryColor.withValues(alpha: 0.08),
            label: 'نام و نام خانوادگی',
            value: _displayName,
          ),
          _infoDivider(),
          _infoRow(
            icon: Icons.email_outlined,
            iconColor: const Color(0xFF0891B2),
            iconBg: const Color(0xFFECFEFF),
            label: 'ایمیل',
            value: _email.isNotEmpty ? _email : 'ایمیل ثبت نشده',
          ),
        ],
      ),
    );
  }

  // ── کارت تنظیمات ────────────────────────────────────────────────
  Widget _buildSettingsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('تنظیمات', Icons.settings_outlined),
          const SizedBox(height: 12),

          _settingsRow(
            icon: Icons.lock_outline_rounded,
            iconColor: const Color(0xFF7C3AED),
            iconBg: const Color(0xFFF5F3FF),
            label: 'تغییر رمز عبور',
            onTap: () => _showComingSoon('تغییر رمز عبور'),
          ),
          _settingsDivider(),
          _settingsRow(
            icon: Icons.notifications_outlined,
            iconColor: const Color(0xFFF59E0B),
            iconBg: const Color(0xFFFFFBEB),
            label: 'اعلان‌ها',
            onTap: () => _showComingSoon('اعلان‌ها'),
          ),
          _settingsDivider(),
          _settingsRow(
            icon: Icons.info_outline_rounded,
            iconColor: const Color(0xFF059669),
            iconBg: const Color(0xFFECFDF5),
            label: 'درباره TripSync',
            onTap: () => _showComingSoon('درباره TripSync'),
          ),
        ],
      ),
    );
  }

  Widget _settingsRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(right: 54),
      color: AppColors.borderColor,
    );
  }

  // ── دکمه خروج ───────────────────────────────────────────────────
  Widget _buildLogoutButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.errorColor.withValues(alpha: 0.30),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.errorColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoggingOut ? null : _handleLogout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoggingOut
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: AppColors.errorColor,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'خروج از حساب',
                    style: TextStyle(
                      color: AppColors.errorColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Transform.rotate(
                    angle: math.pi,
                    child: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.errorColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── helpers ──────────────────────────────────────────────────────
  Widget _decorCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryColor, size: 17),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(right: 54),
      color: AppColors.borderColor,
    );
  }
}

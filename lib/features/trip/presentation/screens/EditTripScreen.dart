import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tripsync/core/theme/app_colors.dart';
import 'package:tripsync/core/utils/app_date_formatter.dart';
import 'package:tripsync/features/trip/data/models/trip_model.dart';
import 'package:tripsync/features/trip/data/models/member_model.dart';
import 'package:tripsync/features/trip/data/services/trip_service.dart';
import 'package:tripsync/features/trip/presentation/widget/date_picker/persian_date_picker_sheet.dart';

class EditTripScreen extends StatefulWidget {
  final TripModel trip;

  const EditTripScreen({super.key, required this.trip});

  @override
  State<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends State<EditTripScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _destinationController = TextEditingController();

  final TripService _tripService = TripService();

  DateTime? _startDate;
  bool _isSaving = false;

  List<MemberModel> _members = [];
  bool _isLoadingMembers = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    // ── پر کردن فیلدها با داده‌های موجود ──────────────────────────
    _titleController.text = widget.trip.title;
    _destinationController.text = widget.trip.destination;
    _startDate = widget.trip.startDate;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();

    _loadMembers();
  }

  @override
  void dispose() {
    _animController.dispose();
    _titleController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await _tripService.getTripMembers(widget.trip.id);
      setState(() => _members = members);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _isLoadingMembers = false);
    }
  }

  // ── date picker ──────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await PersianDatePickerSheet.show(
      context,
      initialDate: _startDate,
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  // ── ذخیره تغییرات ────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null) {
      _showSnack('لطفاً تاریخ سفر را انتخاب کنید', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _tripService.updateTrip(
        tripId: widget.trip.id,
        title: _titleController.text.trim(),
        destination: _destinationController.text.trim(),
        startDate: _startDate!,
      );

      if (!mounted) return;
      _showSnack('سفر با موفقیت ویرایش شد');
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('خطا: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── حذف عضو ─────────────────────────────────────────────────────
  Future<void> _removeMember(MemberModel member) async {
    final confirmed = await _showRemoveDialog(member.fullName);
    if (confirmed != true || !mounted) return;

    // try {
    //   await _tripService.removeMember(
    //     tripId: widget.trip.id,
    //     userId: member.userId,
    //   );
    //   setState(() => _members.removeWhere((m) => m.userId == member.userId));
    //   _showSnack('عضو با موفقیت حذف شد');
    // } catch (e) {
    //   if (!mounted) return;
    //   _showSnack('خطا در حذف عضو: $e', isError: true);
    // }
  }

  Future<bool?> _showRemoveDialog(String name) {
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
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.errorColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person_remove_rounded,
                    color: AppColors.errorColor,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'حذف عضو',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$name از سفر حذف می‌شه. مطمئنی؟',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => context.pop(false),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.borderColor,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () => context.pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.errorColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'حذف کن',
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

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError
            ? AppColors.errorColor
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: CustomScrollView(
          slivers: [
            // ── Hero Header ───────────────────────────────────────
            _buildHeroHeader(context),

            // ── محتوا ────────────────────────────────────────────
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── کارت فرم ─────────────────────────────
                          _buildFormCard(),
                          const SizedBox(height: 20),

                          // ── مدیریت اعضا ──────────────────────────
                          _buildMembersCard(),
                          const SizedBox(height: 28),

                          // ── دکمه‌های عمل ─────────────────────────
                          _buildActions(),
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

  // ── Hero Header ──────────────────────────────────────────────────
  SliverAppBar _buildHeroHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: AppColors.primaryColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: _buildHeroBackground(context),
      ),
    );
  }

  Widget _buildHeroBackground(BuildContext context) {
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
          Positioned(top: -40, left: -40, child: _decorCircle(160, 0.07)),
          Positioned(bottom: -50, right: -20, child: _decorCircle(180, 0.07)),
          Positioned(top: 60, left: 100, child: _decorCircle(60, 0.05)),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ویرایش سفر',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.trip.title,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.70),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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

  // ── کارت فرم ────────────────────────────────────────────────────
  Widget _buildFormCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader('اطلاعات سفر', Icons.info_outline_rounded),
          const SizedBox(height: 20),

          // عنوان
          _fieldLabel('عنوان سفر', Icons.edit_note_rounded),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _titleController,
            hint: 'مثلاً: سفر رامسر',
            icon: Icons.card_travel_rounded,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'عنوان نمی‌تواند خالی باشد';
              }
              if (v.trim().length < 2) return 'عنوان باید حداقل ۲ کاراکتر باشد';
              return null;
            },
          ),

          const SizedBox(height: 20),
          _divider(),
          const SizedBox(height: 20),

          // مقصد
          _fieldLabel('مقصد', Icons.location_on_outlined),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _destinationController,
            hint: 'مثلاً: رامسر',
            icon: Icons.location_on_rounded,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'مقصد نمی‌تواند خالی باشد';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),
          _divider(),
          const SizedBox(height: 20),

          // تاریخ
          _fieldLabel('تاریخ شروع', Icons.calendar_month_outlined),
          const SizedBox(height: 8),
          _buildDateField(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.textDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFB0BAC9), fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        filled: true,
        fillColor: AppColors.backgroundColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.borderColor,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.errorColor, width: 2),
        ),
        errorStyle: const TextStyle(color: AppColors.errorColor, fontSize: 12),
      ),
    );
  }

  Widget _buildDateField() {
    final hasDate = _startDate != null;
    return GestureDetector(
      onTap: _pickDate,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hasDate
              ? AppColors.primaryColor.withValues(alpha: 0.05)
              : AppColors.backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasDate
                ? AppColors.primaryColor.withValues(alpha: 0.40)
                : AppColors.borderColor,
            width: hasDate ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: hasDate ? AppColors.primaryColor : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasDate
                    ? AppDateFormatter.toJalali(_startDate!)
                    : 'انتخاب تاریخ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: hasDate ? FontWeight.w600 : FontWeight.w400,
                  color: hasDate ? AppColors.textDark : const Color(0xFFB0BAC9),
                ),
              ),
            ),
            if (hasDate)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'انتخاب شد',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
              )
            else
              const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // ── کارت مدیریت اعضا ────────────────────────────────────────────
  Widget _buildMembersCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('مدیریت اعضا', Icons.group_outlined),
          const SizedBox(height: 16),

          if (_isLoadingMembers)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              ),
            )
          else if (_members.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.group_rounded,
                        color: AppColors.primaryColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'هنوز عضوی وجود ندارد',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _members.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (_, index) =>
                  _buildMemberTile(_members[index], index),
            ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(MemberModel member, int index) {
    final avatarColors = [
      AppColors.primaryColor,
      const Color(0xFF0891B2),
      const Color(0xFF7C3AED),
      const Color(0xFF059669),
      const Color(0xFFDB2777),
    ];
    final color = avatarColors[index % avatarColors.length];
    final initials = member.fullName.isNotEmpty
        ? member.fullName.trim().split(' ').map((w) => w[0]).take(2).join()
        : '?';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // آواتار
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withValues(alpha: 0.30),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // اسم
          Expanded(
            child: Text(
              member.fullName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),

          // دکمه حذف عضو
          GestureDetector(
            onTap: () => _removeMember(member),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.errorColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.errorColor.withValues(alpha: 0.20),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.person_remove_rounded,
                color: AppColors.errorColor,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── دکمه‌های ذخیره و انصراف ─────────────────────────────────────
  Widget _buildActions() {
    return Row(
      children: [
        // انصراف
        Expanded(
          child: SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: _isSaving ? null : () => context.pop(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: AppColors.borderColor,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'انصراف',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // ذخیره
        Expanded(
          flex: 2,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryColor, Color(0xFF1D4ED8)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'ذخیره تغییرات',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // ── helpers ──────────────────────────────────────────────────────
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

  Widget _fieldLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(height: 1, color: AppColors.borderColor);
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tripsync/core/theme/app_colors.dart';
import 'package:tripsync/core/utils/app_date_formatter.dart';
import 'package:tripsync/core/widgets/appbar_primary.dart';
import 'package:tripsync/features/trip/data/services/trip_service.dart';
import 'package:tripsync/features/trip/presentation/widget/date_picker/persian_date_picker_sheet.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _destinationController = TextEditingController();

  final TripService _tripService = TripService();

  DateTime? _startDate;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _titleController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  // ── date picker — باتم‌شیت سفارشی شمسی ────────────────────────────
  Future<void> _pickDate() async {
    final picked = await PersianDatePickerSheet.show(
      context,
      initialDate: _startDate,
    );

    if (picked == null) return;

    setState(() => _startDate = picked);
  }

  // ── submit ───────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً تاریخ سفر را انتخاب کنید')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      await _tripService.createTrip(
        title: _titleController.text.trim(),
        destination: _destinationController.text.trim(),
        startDate: _startDate!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('سفر با موفقیت ایجاد شد')));

      context.pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا: $e')));
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
        backgroundColor: AppColors.backgroundColor,
        appBar: AppPrimaryAppBar(title: 'ایجاد سفر جدید'),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
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
                    // ── ۱. Cover placeholder ───────────────────────
                    _buildCoverSection(),
                    const SizedBox(height: 28),

                    // ── ۲. فرم ────────────────────────────────────
                    _buildFormCard(),
                    const SizedBox(height: 28),

                    // ── ۳. دکمه ایجاد ─────────────────────────────
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Cover Section ────────────────────────────────────────────────
  Widget _buildCoverSection() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withValues(alpha: 0.60),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            left: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            right: -10,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 80,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.30),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.travel_explore_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'سفر جدید شما',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'جزئیات سفرت رو پایین وارد کن',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── فرم ─────────────────────────────────────────────────────────
  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFieldLabel('عنوان سفر', Icons.edit_note_rounded),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _titleController,
            hint: 'مثلاً: سفر رامسر',
            icon: Icons.card_travel_rounded,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'عنوان سفر نمی‌تواند خالی باشد';
              }
              if (v.trim().length < 2) return 'عنوان باید حداقل ۲ کاراکتر باشد';
              return null;
            },
          ),

          const SizedBox(height: 20),
          _buildDivider(),
          const SizedBox(height: 20),

          _buildFieldLabel('مقصد', Icons.location_on_outlined),
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
          _buildDivider(),
          const SizedBox(height: 20),

          _buildFieldLabel('تاریخ شروع', Icons.calendar_month_outlined),
          const SizedBox(height: 8),
          _buildDatePicker(),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ],
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
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12),
      ),
    );
  }

  // ── فیلد تاریخ — باز کردن باتم‌شیت سفارشی ──────────────────────────
  Widget _buildDatePicker() {
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
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: AppColors.borderColor);
  }

  // ── دکمه ایجاد سفر ──────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withValues(alpha: 0.60),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.40),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_location_alt_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'ایجاد سفر',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

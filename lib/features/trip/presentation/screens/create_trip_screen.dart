import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tripsync/core/theme/app_colors.dart';
import 'package:tripsync/core/utils/app_date_formatter.dart';
import 'package:tripsync/core/utils/snackbar_helper.dart';
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
      SnackbarHelper.showWarning(context, 'لطفاً تاریخ سفر را انتخاب کنید');
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

      SnackbarHelper.showSuccess(context, 'سفر با موفقیت ایجاد شد');

      context.pop(true);
    } catch (e) {
      if (!mounted) return;

      SnackbarHelper.showError(context, 'خطا در ایجاد سفر');
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
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withValues(alpha: 0.35),
            AppColors.primaryColor.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.20),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_rounded,
              size: 50,
              color: AppColors.primaryColor.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 8),
            Text(
              'افزودن تصویر کاور (به زودی)',
              style: TextStyle(
                color: AppColors.primaryColor.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Form Card ────────────────────────────────────────────────────
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('عنوان سفر', Icons.title_rounded),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _titleController,
            hint: 'مثال: سفر به شمال',
            validator: (val) =>
                (val == null || val.trim().isEmpty) ? 'عنوان الزامی است' : null,
          ),
          const SizedBox(height: 24),
          _buildLabel('مقصد', Icons.location_on_rounded),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _destinationController,
            hint: 'مثال: رامسر',
            validator: (val) =>
                (val == null || val.trim().isEmpty) ? 'مقصد الزامی است' : null,
          ),
          const SizedBox(height: 24),
          _buildLabel('تاریخ شروع', Icons.calendar_today_rounded),
          const SizedBox(height: 10),
          _buildDatePicker(),
        ],
      ),
    );
  }

  // ── Label ────────────────────────────────────────────────────────
  Widget _buildLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryColor),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  // ── فیلد متنی ─────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: AppColors.backgroundColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
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
                ? AppColors.primaryColor
                : Colors.grey.shade300.withValues(alpha: 0.5),
            width: hasDate ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.event_rounded,
              color: hasDate ? AppColors.primaryColor : Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasDate
                    ? AppDateFormatter.toJalali(_startDate!)
                    : 'انتخاب تاریخ',
                style: TextStyle(
                  fontSize: 14,
                  color: hasDate
                      ? AppColors.primaryColor
                      : Colors.grey.shade400,
                  fontWeight: hasDate ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down_rounded,
              color: hasDate ? AppColors.primaryColor : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // ── دکمه ایجاد ───────────────────────────────────────────────────
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

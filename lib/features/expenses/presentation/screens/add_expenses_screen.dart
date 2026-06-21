import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tripsync/core/enums/expense_category.dart';
import 'package:tripsync/core/theme/app_colors.dart';
import 'package:tripsync/core/utils/app_date_formatter.dart';
import 'package:tripsync/features/expenses/presentation/providers/expense_providers.dart';
import 'package:tripsync/features/expenses/presentation/providers/trip_members_provider.dart';
import 'package:tripsync/features/expenses/presentation/widgets/appbar_primary.dart';
import 'package:tripsync/features/expenses/presentation/widgets/expense_form_widgets.dart';
import 'package:tripsync/features/trip/data/models/trip_member_model.dart';
import 'package:tripsync/features/trip/presentation/widget/date_picker/persian_date_picker_sheet.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String tripId;

  const AddExpenseScreen({super.key, required this.tripId});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  ExpenseCategory? _category;
  String? _payerUserId;
  final Set<String> _splitUserIds = {};
  DateTime _date = DateTime.now();

  bool _isSaving = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await PersianDatePickerSheet.show(
      context,
      initialDate: _date,
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _onPayerSelected(String userId) {
    setState(() => _payerUserId = userId);
  }

  void _onSplitToggled(String userId) {
    setState(() {
      if (_splitUserIds.contains(userId)) {
        _splitUserIds.remove(userId);
      } else {
        _splitUserIds.add(userId);
      }
    });
  }

  void _selectAllForSplit(List<TripMemberModel> members) {
    setState(() {
      if (_splitUserIds.length == members.length) {
        _splitUserIds.clear();
      } else {
        _splitUserIds
          ..clear()
          ..addAll(members.map((m) => m.id));
      }
    });
  }

  double? get _parsedAmount => double.tryParse(_amountController.text.trim());

  // ── ذخیره هزینه ──────────────────────────────────────────────────
  Future<void> _save() async {
    // اعتبارسنجی فیلدهای متنی فرم (توضیحات، مبلغ، دسته‌بندی)
    if (!_formKey.currentState!.validate()) return;

    if (_payerUserId == null) {
      _showSnack('لطفاً پرداخت‌کننده را انتخاب کنید', isError: true);
      return;
    }

    if (_splitUserIds.isEmpty) {
      _showSnack('حداقل یک نفر را برای تقسیم هزینه انتخاب کنید', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(expenseRepositoryProvider);
      await repository.addExpense(
        tripId: widget.tripId,
        description: _descriptionController.text.trim(),
        amount: _parsedAmount!,
        paidBy: _payerUserId!,
        category: _category!.value,
        date: _date,
        splitBetweenUserIds: _splitUserIds.toList(),
      );

      if (!mounted) return;

      // رفرش لیست هزینه‌ها و جمع کل برای این سفر
      ref.invalidate(expenseListProvider(widget.tripId));
      ref.invalidate(expenseTotalProvider(widget.tripId));

      _showSnack('هزینه با موفقیت ثبت شد');
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('خطا در ثبت هزینه: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
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
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError
            ? AppColors.errorColor
            : AppColors.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // لیست اعضای سفر — برای انتخاب پرداخت‌کننده و تقسیم هزینه
    final membersAsync = ref.watch(tripMembersProvider(widget.tripId));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppPrimaryAppBar(title: 'افزودن هزینه'),
        body: membersAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'خطا در دریافت اعضای سفر: $error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.errorColor),
              ),
            ),
          ),
          data: (members) => _buildForm(members),
        ),
      ),
    );
  }

  Widget _buildForm(List<TripMemberModel> members) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── کارت اطلاعات اصلی ──────────────────────────
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionHeader(
                          'اطلاعات هزینه',
                          Icons.receipt_long_outlined,
                        ),
                        const SizedBox(height: 20),

                        _fieldLabel('توضیحات', Icons.edit_note_rounded),
                        const SizedBox(height: 8),
                        _buildDescriptionField(),

                        const SizedBox(height: 20),
                        _divider(),
                        const SizedBox(height: 20),

                        _fieldLabel('مبلغ (تومان)', Icons.payments_outlined),
                        const SizedBox(height: 8),
                        _buildAmountField(),

                        const SizedBox(height: 20),
                        _divider(),
                        const SizedBox(height: 20),

                        _fieldLabel('دسته‌بندی', Icons.category_outlined),
                        const SizedBox(height: 8),
                        CategoryDropdown(
                          value: _category,
                          onChanged: (v) => setState(() => _category = v),
                        ),

                        const SizedBox(height: 20),
                        _divider(),
                        const SizedBox(height: 20),

                        _fieldLabel('تاریخ', Icons.calendar_month_outlined),
                        const SizedBox(height: 8),
                        _buildDateField(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── کارت پرداخت‌کننده ───────────────────────────
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionHeader(
                          'پرداخت‌کننده',
                          Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 16),
                        if (members.isEmpty)
                          _buildNoMembersHint()
                        else
                          PayerSelector(
                            members: members,
                            selectedUserId: _payerUserId,
                            onSelected: _onPayerSelected,
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── کارت تقسیم هزینه ────────────────────────────
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _sectionHeader(
                                'تقسیم بین',
                                Icons.groups_outlined,
                              ),
                            ),
                            if (members.isNotEmpty)
                              GestureDetector(
                                onTap: () => _selectAllForSplit(members),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _splitUserIds.length == members.length
                                        ? 'حذف همه'
                                        : 'انتخاب همه',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (members.isEmpty)
                          _buildNoMembersHint()
                        else
                          SplitMembersSelector(
                            members: members,
                            selectedUserIds: _splitUserIds,
                            onToggle: _onSplitToggled,
                            totalAmount: _parsedAmount,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── دکمه ثبت — همیشه پایین صفحه ─────────────────────────
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 2,
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.textDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'مثلاً: شام رستوران',
        hintStyle: const TextStyle(color: Color(0xFFB0BAC9), fontSize: 14),
        prefixIcon: const Icon(
          Icons.short_text_rounded,
          color: AppColors.textMuted,
          size: 20,
        ),
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
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'توضیحات نمی‌تواند خالی باشد';
        }
        return null;
      },
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      style: const TextStyle(
        fontSize: 16,
        color: AppColors.primaryColor,
        fontWeight: FontWeight.w800,
      ),
      onChanged: (_) => setState(() {}), // آپدیت زنده‌ی سهم هر نفر
      decoration: InputDecoration(
        hintText: '۰',
        hintStyle: const TextStyle(color: Color(0xFFB0BAC9), fontSize: 14),
        suffixText: 'تومان',
        suffixStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: const Icon(
          Icons.payments_rounded,
          color: AppColors.textMuted,
          size: 20,
        ),
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
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'مبلغ نمی‌تواند خالی باشد';
        }
        final parsed = double.tryParse(v.trim());
        if (parsed == null || parsed <= 0) {
          return 'مبلغ معتبر وارد کنید';
        }
        return null;
      },
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.40),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: AppColors.primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppDateFormatter.toJalali(_date),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
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

  Widget _buildNoMembersHint() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: const Text(
        'هنوز عضوی در این سفر نیست',
        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderColor, width: 1)),
      ),
      child: SafeArea(
        top: false,
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
                blurRadius: 18,
                offset: const Offset(0, 8),
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
                        Icons.check_circle_outline_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'ثبت هزینه',
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
        ),
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

import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:tripsync/core/theme/app_colors.dart';

import 'year_picker_section.dart';
import 'month_picker_section.dart';
import 'day_picker_section.dart';

/// باتم‌شیت انتخاب تاریخ شمسی — مقدار خروجی DateTime میلادی است
/// (برای ذخیره در Supabase)
class PersianDatePickerSheet extends StatefulWidget {
  final DateTime? initialDate;

  const PersianDatePickerSheet({super.key, this.initialDate});

  /// helper برای نمایش باتم‌شیت
  static Future<DateTime?> show(BuildContext context, {DateTime? initialDate}) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PersianDatePickerSheet(initialDate: initialDate),
    );
  }

  @override
  State<PersianDatePickerSheet> createState() => _PersianDatePickerSheetState();
}

class _PersianDatePickerSheetState extends State<PersianDatePickerSheet> {
  late Jalali _selected;

  static const List<String> _months = MonthPickerSection.months;

  static const List<String> _persianDigits = [
    '۰',
    '۱',
    '۲',
    '۳',
    '۴',
    '۵',
    '۶',
    '۷',
    '۸',
    '۹',
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate != null
        ? Jalali.fromDateTime(widget.initialDate!)
        : Jalali.now();
  }

  // ── helpers ─────────────────────────────────────────────────────
  String _toPersianDigits(int number) {
    return number
        .toString()
        .split('')
        .map((d) => _persianDigits[int.parse(d)])
        .join();
  }

  String get _previewText {
    return '${_toPersianDigits(_selected.day)} '
        '${_months[_selected.month - 1]} '
        '${_toPersianDigits(_selected.year)}';
  }

  void _onYearSelected(int year) {
    final maxDay = Jalali(year, _selected.month, 1).monthLength;
    final day = _selected.day > maxDay ? maxDay : _selected.day;
    setState(() => _selected = Jalali(year, _selected.month, day));
  }

  void _onMonthSelected(int month) {
    final maxDay = Jalali(_selected.year, month, 1).monthLength;
    final day = _selected.day > maxDay ? maxDay : _selected.day;
    setState(() => _selected = Jalali(_selected.year, month, day));
  }

  void _onDaySelected(int day) {
    setState(() => _selected = Jalali(_selected.year, _selected.month, day));
  }

  void _onConfirm() {
    Navigator.of(context).pop(_selected.toDateTime());
  }

  void _onCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final now = Jalali.now();
    final daysInMonth = Jalali(_selected.year, _selected.month, 1).monthLength;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // ── handle ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // ── محتوای اسکرول‌شونده ─────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── هدر ──────────────────────────────────────
                      const SizedBox(height: 8),
                      const Text(
                        'انتخاب تاریخ سفر',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'تاریخ شروع سفر را انتخاب کنید',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── کارت پیش‌نمایش تاریخ ─────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.25,
                            ),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              color: AppColors.primaryColor,
                              size: 22,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _previewText,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── انتخاب سال ───────────────────────────────
                      _sectionLabel('سال'),
                      const SizedBox(height: 10),
                      YearPickerSection(
                        selectedYear: _selected.year,
                        currentYear: now.year,
                        onYearSelected: _onYearSelected,
                      ),

                      const SizedBox(height: 22),

                      // ── انتخاب ماه ───────────────────────────────
                      _sectionLabel('ماه'),
                      const SizedBox(height: 10),
                      MonthPickerSection(
                        selectedMonth: _selected.month,
                        onMonthSelected: _onMonthSelected,
                      ),

                      const SizedBox(height: 22),

                      // ── انتخاب روز ───────────────────────────────
                      _sectionLabel('روز'),
                      const SizedBox(height: 10),
                      DayPickerSection(
                        selectedDay: _selected.day,
                        daysInMonth: daysInMonth,
                        onDaySelected: _onDaySelected,
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // ── دکمه‌های پایین ──────────────────────────────────
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: AppColors.borderColor, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    // لغو
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _onCancel,
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
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // تأیید
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryColor,
                              AppColors.primaryColor.withValues(alpha: 0.60),
                            ],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _onConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'تأیید تاریخ',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
      ),
    );
  }
}

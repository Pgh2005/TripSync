import 'package:flutter/material.dart';
import 'package:tripsync/core/enums/expense_category.dart';
import 'package:tripsync/core/theme/app_colors.dart';
import 'package:tripsync/features/trip/data/models/trip_member_model.dart';

class CategoryDropdown extends StatelessWidget {
  final ExpenseCategory? value;
  final ValueChanged<ExpenseCategory?> onChanged;

  const CategoryDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static IconData _iconFor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.transport:
        return Icons.directions_car_rounded;
      case ExpenseCategory.hotel:
        return Icons.hotel_rounded;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_rounded;
      case ExpenseCategory.entertainment:
        return Icons.celebration_rounded;
      case ExpenseCategory.other:
        return Icons.payments_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ExpenseCategory>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.textMuted,
      ),
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.textDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(
          value != null ? _iconFor(value!) : Icons.category_outlined,
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
      ),
      hint: const Text(
        'انتخاب دسته‌بندی',
        style: TextStyle(color: Color(0xFFB0BAC9), fontSize: 14),
      ),
      validator: (v) => v == null ? 'دسته‌بندی را انتخاب کنید' : null,
      items: ExpenseCategory.values.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconFor(category), size: 18, color: AppColors.primaryColor),
              const SizedBox(width: 8),
              Text(category.labelFa),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// انتخاب پرداخت‌کننده — تک‌انتخابی، لیست افقی
// ──────────────────────────────────────────────────────────────────
class PayerSelector extends StatelessWidget {
  final List<TripMemberModel> members;
  final String? selectedUserId;
  final ValueChanged<String> onSelected;

  const PayerSelector({
    super.key,
    required this.members,
    required this.selectedUserId,
    required this.onSelected,
  });

  static const List<Color> _avatarColors = [
    AppColors.primaryColor,
    Color(0xFF0891B2),
    Color(0xFF7C3AED),
    Color(0xFF059669),
    Color(0xFFDB2777),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: members.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final member = members[index];
          final isSelected = member.id == selectedUserId;
          final color = _avatarColors[index % _avatarColors.length];
          final initials = member.fullName.trim().isNotEmpty
              ? member.fullName
                    .trim()
                    .split(' ')
                    .map((w) => w[0])
                    .take(2)
                    .join()
              : '?';

          return GestureDetector(
            onTap: () => onSelected(member.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 68,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryColor.withValues(alpha: 0.08)
                    : AppColors.backgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryColor
                      : AppColors.borderColor,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
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
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    member.fullName.split(' ').first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.primaryColor
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// انتخاب اعضای سهیم در هزینه — چندانتخابی + پیش‌نمایش سهم هر نفر
// ──────────────────────────────────────────────────────────────────
class SplitMembersSelector extends StatelessWidget {
  final List<TripMemberModel> members;
  final Set<String> selectedUserIds;
  final ValueChanged<String> onToggle;
  final double? totalAmount;

  const SplitMembersSelector({
    super.key,
    required this.members,
    required this.selectedUserIds,
    required this.onToggle,
    this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    // محاسبه سهم هر نفر — تقسیم مساوی مبلغ کل بین اعضای انتخاب‌شده
    final perPersonAmount =
        (totalAmount != null && totalAmount! > 0 && selectedUserIds.isNotEmpty)
        ? totalAmount! / selectedUserIds.length
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: members.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final member = members[index];
            final isChecked = selectedUserIds.contains(member.id);

            return GestureDetector(
              onTap: () => onToggle(member.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isChecked
                      ? AppColors.primaryColor.withValues(alpha: 0.06)
                      : AppColors.backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isChecked
                        ? AppColors.primaryColor.withValues(alpha: 0.40)
                        : AppColors.borderColor,
                    width: isChecked ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isChecked
                            ? AppColors.primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: isChecked
                              ? AppColors.primaryColor
                              : AppColors.borderColor,
                          width: 1.5,
                        ),
                      ),
                      child: isChecked
                          ? const Icon(
                              Icons.check_rounded,
                              size: 15,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        member.fullName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isChecked
                              ? AppColors.textDark
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                    if (isChecked && perPersonAmount != null)
                      Text(
                        '${perPersonAmount.toStringAsFixed(0)} تومان',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        if (selectedUserIds.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'بین ${selectedUserIds.length} نفر تقسیم می‌شه',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

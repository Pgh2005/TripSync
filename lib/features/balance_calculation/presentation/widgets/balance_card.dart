import 'package:flutter/material.dart';
import 'package:tripsync/core/theme/app_colors.dart';
import 'package:tripsync/core/utils/money_formatter.dart';
import '../../data/models/settlement.dart';

class SettlementCard extends StatelessWidget {
  final Settlement settlement;

  const SettlementCard({super.key, required this.settlement});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── آواتار بدهکار ──
          _AvatarChip(
            name: settlement.fromUserName,
            label: 'بدهکار',
            color: Colors.red.shade400,
          ),

          // ── فلش + مبلغ ──
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${settlement.amount.toMoney()} ت',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.grey,
                  size: 20,
                ),
              ],
            ),
          ),

          // ── آواتار طلبکار ──
          _AvatarChip(
            name: settlement.toUserName,
            label: 'طلبکار',
            color: Colors.green.shade400,
          ),
        ],
      ),
    );
  }
}

class _AvatarChip extends StatelessWidget {
  final String name;
  final String label;
  final Color color;

  const _AvatarChip({
    required this.name,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join();

    return Column(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            initials.toUpperCase(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 90,
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}

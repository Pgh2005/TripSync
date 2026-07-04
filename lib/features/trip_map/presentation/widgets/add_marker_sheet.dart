import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripsync/core/utils/snackbar_helper.dart';

import '../../../../core/enums/marker_visibility.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/trip_map_repository_provider.dart';
import '../providers/trip_markers_provider.dart';

class AddMarkerSheet extends ConsumerStatefulWidget {
  final String tripId;
  final LatLng point;

  const AddMarkerSheet({super.key, required this.tripId, required this.point});

  @override
  ConsumerState<AddMarkerSheet> createState() => _AddMarkerSheetState();
}

class _AddMarkerSheetState extends ConsumerState<AddMarkerSheet> {
  final TextEditingController _titleController = TextEditingController();
  MarkerVisibility _visibility = MarkerVisibility.tripShared;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _saveMarker() async {
    if (_isSaving) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      SnackbarHelper.showError(context, 'برای ثبت مکان باید وارد حساب شوید');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(tripMapRepositoryProvider);

      await repository.createMarker(
        tripId: widget.tripId,
        currentUserId: user.id,
        latitude: widget.point.latitude,
        longitude: widget.point.longitude,
        visibility: _visibility,
      );

      ref.invalidate(tripMarkersProvider(widget.tripId));

      if (!mounted) return;

      SnackbarHelper.showSuccess(context, 'مکان با موفقیت ثبت شد');
      context.pop(true); // بستن شیت فقط در صورت موفقیت
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error saving marker: $e');
      SnackbarHelper.showError(context, 'خطا در ثبت مکان: $e');

      setState(() {
        _isSaving = false; // باز کردن قفل دکمه در صورت وقوع خطا برای تلاش مجدد
      });
    }
  }

  Widget _buildVisibilityCard({
    required MarkerVisibility value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _visibility == value;

    return InkWell(
      onTap: () {
        setState(() {
          _visibility = value;
        });
      },
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withValues(alpha: 0.10)
              : AppColors.backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.borderColor,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryColor.withValues(alpha: 0.12)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppColors.primaryColor
                    : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Radio<MarkerVisibility>(value: value),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.borderColor,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'ثبت مکان جدید',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'یک مارکر جدید برای این سفر ثبت می‌شود. عنوان و توضیحات کامل در مراحل بعدی به صورت Entry ثبت خواهند شد.',
                    style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'مختصات انتخاب‌شده',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'عرض جغرافیایی (Lat): ${widget.point.latitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'طول جغرافیایی (Lng): ${widget.point.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _titleController,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      labelText: 'عنوان اولیه (اختیاری)',
                      hintText: 'مثلاً: هتل، کافه، ساحل...',
                      helperText:
                          'این عنوان به عنوان داده موقت ثبت می‌شود و در مراحل بعدی به Entry تبدیل خواهد شد.',
                      filled: true,
                      fillColor: AppColors.backgroundColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: AppColors.primaryColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'سطح نمایش',

                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),

                  RadioGroup<MarkerVisibility>(
                    groupValue: _visibility,
                    onChanged: (MarkerVisibility? newValue) {
                      // اضافه شدن علامت سوال
                      if (newValue == null) return;
                      setState(() {
                        _visibility = newValue;
                      });
                    },
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        _buildVisibilityCard(
                          value: MarkerVisibility.tripShared,
                          title: 'مشترک در سفر',
                          subtitle: 'برای اعضای همین سفر قابل مشاهده باشد',
                          icon: Icons.groups_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildVisibilityCard(
                          value: MarkerVisibility.ownerOnly,
                          title: 'فقط برای من',
                          subtitle: 'فقط خودم این مارکر را ببینم',
                          icon: Icons.lock_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveMarker,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.primaryColor
                            .withValues(alpha: 0.5),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'ثبت مکان',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

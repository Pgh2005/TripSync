import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripsync/core/utils/snackbar_helper.dart';
import 'package:tripsync/features/trip_map/presentation/providers/marker_media_service_provider.dart';
import '../../../../core/enums/marker_media_type.dart';
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
  String _loadingMessage = 'ثبت مکان...';

  // لیست فایل‌های انتخاب شده موقت
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // متد انتخاب تصاویر از گالری
  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80, // فشرده‌سازی جزئی جهت بهینه‌سازی آپلود
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(context, 'خطا در انتخاب تصاویر: $e');
    }
  }

  // متد حذف یک تصویر از لیست موقت پیش‌نمایش
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
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
      _loadingMessage = 'در حال ثبت مکان اولیه...';
    });

    try {
      final repository = ref.read(tripMapRepositoryProvider);
      final mediaService = ref.read(markerMediaServiceProvider);

      final createdMarker = await repository.createMarker(
        tripId: widget.tripId,
        currentUserId: user.id,
        latitude: widget.point.latitude,
        longitude: widget.point.longitude,
        visibility: _visibility,
        title: _titleController.text.trim(), // این خط را اضافه کن
      );

      // ۲. آپلود عکس‌ها (در صورت وجود)
      if (_selectedImages.isNotEmpty) {
        for (int i = 0; i < _selectedImages.length; i++) {
          if (!mounted) return;
          setState(() {
            _loadingMessage =
                'آپلود تصویر ${i + 1} از ${_selectedImages.length}...';
          });

          await mediaService.uploadMedia(
            markerId: createdMarker.id,
            createdBy: user.id,
            file: _selectedImages[i],
            type: MarkerMediaType.image,
            visibility: _visibility,
          );
        }
      }

      ref.invalidate(tripMarkersProvider(widget.tripId));

      if (!mounted) return;

      SnackbarHelper.showSuccess(context, 'مکان و تصاویر با موفقیت ثبت شدند');
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error saving marker or uploading media: $e');
      SnackbarHelper.showError(context, 'خطا در ثبت اطلاعات: $e');

      setState(() {
        _isSaving = false;
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
                    'یک مارکر جدید برای این سفر ثبت می‌شود. همچنین می‌توانید عکس‌های مربوط به این موقعیت را اضافه کنید.',
                    style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _titleController,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      labelText: 'عنوان اولیه (اختیاری)',
                      hintText: 'مثلاً: هتل، کافه، ساحل...',
                      helperText: 'این عنوان به عنوان داده موقت ثبت می‌شود.',
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

                  // بخش مدیریت عکس‌ها
                  const Text(
                    'تصاویر موقعیت مکانی',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // اسکرول افقی تصاویر انتخاب شده
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _selectedImages.length) {
                          // دکمه اضافه کردن عکس جدید
                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: InkWell(
                              onTap: _isSaving ? null : _pickImages,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: 100,
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.borderColor,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: AppColors.primaryColor,
                                  size: 32,
                                ),
                              ),
                            ),
                          );
                        }

                        // کارت نمایش پیش‌نمایش تصویر به همراه دکمه حذف
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  _selectedImages[index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (!_isSaving)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
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
                      if (newValue != null) {
                        setState(() {
                          _visibility = newValue;
                        });
                      }
                    },
                    child: Column(
                      children: [
                        _buildVisibilityCard(
                          value: MarkerVisibility.ownerOnly,
                          title: 'فقط برای من',
                          subtitle: 'فقط خودت این مارکر را می‌بینی',
                          icon: Icons.lock_outline,
                        ),
                        const SizedBox(height: 12),
                        _buildVisibilityCard(
                          value: MarkerVisibility.tripShared,
                          title: 'اشتراکی در سفر',
                          subtitle: 'اعضای سفر این مارکر را می‌بینند',
                          icon: Icons.group_outlined,
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
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _loadingMessage,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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

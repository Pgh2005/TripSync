import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripsync/core/utils/snackbar_helper.dart';
import 'package:tripsync/features/trip_map/data/models/trip_marker_models.dart';
import 'package:tripsync/features/trip_map/presentation/providers/marker_media_service_provider.dart';
import 'package:tripsync/features/trip_map/presentation/widgets/trip_map_status_banner.dart';
import '../../../../core/enums/marker_media_type.dart';
import '../../../../core/enums/marker_visibility.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/trip_map_repository_provider.dart';
import '../providers/trip_markers_provider.dart';

class AddMarkerSheet extends ConsumerStatefulWidget {
  final String tripId;
  final LatLng point;
  final TripMarkerModel? initialMarker;

  const AddMarkerSheet({
    super.key,
    required this.tripId,
    required this.point,
    this.initialMarker,
  });

  bool get isEditMode => initialMarker != null;

  @override
  ConsumerState<AddMarkerSheet> createState() => _AddMarkerSheetState();
}

class _AddMarkerSheetState extends ConsumerState<AddMarkerSheet> {
  final TextEditingController _titleController = TextEditingController();
  MarkerVisibility _visibility = MarkerVisibility.tripShared;
  bool _isSaving = false;
  String _loadingMessage = 'ثبت مکان...';
  String? _errorText;

  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final marker = widget.initialMarker;
    if (marker != null) {
      _titleController.text = marker.title ?? '';
      _visibility = marker.visibility;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _mapSaveError(Object error) {
    final raw = error.toString();

    if (raw.contains('SocketException') ||
        raw.contains('network') ||
        raw.contains('Network')) {
      return 'اتصال اینترنت برقرار نیست. دوباره تلاش کن.';
    }

    if (raw.contains('permission') || raw.contains('Permission')) {
      return 'دسترسی لازم برای این عملیات وجود ندارد.';
    }

    if (raw.contains('row-level security') || raw.contains('42501')) {
      return 'اجازه انجام این عملیات را نداری.';
    }

    return 'ذخیره‌سازی انجام نشد. دوباره تلاش کن.';
  }

  Future<void> _pickImages() async {
    try {
      final images = await _picker.pickMultiImage(imageQuality: 80);

      if (images.isEmpty) return;

      setState(() {
        _errorText = null;
        _selectedImages.addAll(images.map((xFile) => File(xFile.path)));
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = 'خطا در انتخاب تصاویر. دوباره تلاش کن.';
      });
    }
  }

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
      _errorText = null;
      _loadingMessage = widget.isEditMode
          ? 'در حال ذخیره تغییرات...'
          : 'در حال ثبت مکان اولیه...';
    });

    try {
      final repository = ref.read(tripMapRepositoryProvider);
      final mediaService = ref.read(markerMediaServiceProvider);

      if (widget.isEditMode) {
        await repository.updateMarker(
          markerId: widget.initialMarker!.id,
          title: _titleController.text.trim(),
          visibility: _visibility,
        );

        ref.invalidate(tripMarkersProvider(widget.tripId));

        if (!mounted) return;
        SnackbarHelper.showSuccess(context, 'تغییرات مکان ذخیره شد');
        Navigator.of(context).pop(true);
        return;
      }

      final createdMarker = await repository.createMarker(
        tripId: widget.tripId,
        currentUserId: user.id,
        latitude: widget.point.latitude,
        longitude: widget.point.longitude,
        visibility: _visibility,
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
      );

      if (_selectedImages.isNotEmpty) {
        for (int index = 0; index < _selectedImages.length; index++) {
          if (!mounted) return;
          setState(() {
            _loadingMessage =
                'آپلود تصویر ${index + 1} از ${_selectedImages.length}...';
          });

          await mediaService.uploadMedia(
            markerId: createdMarker.id,
            createdBy: user.id,
            file: _selectedImages[index],
            type: MarkerMediaType.image,
            visibility: _visibility,
          );
        }
      }

      ref.invalidate(tripMarkersProvider(widget.tripId));

      if (!mounted) return;
      SnackbarHelper.showSuccess(context, 'مکان و تصاویر با موفقیت ثبت شدند');
      context.pop(true);
    } catch (error) {
      if (!mounted) return;
      debugPrint('Error saving marker or uploading media: $error');
      setState(() {
        _errorText = _mapSaveError(error);
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
    final isEditMode = widget.isEditMode;

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
                  Text(
                    isEditMode ? 'ویرایش مکان' : 'ثبت مکان جدید',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEditMode
                        ? 'عنوان و سطح نمایش این مکان را ویرایش کن.'
                        : 'یک مارکر جدید برای این سفر ثبت می‌شود. همچنین می‌توانید عکس‌های مربوط به این موقعیت را اضافه کنید.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_errorText != null) ...[
                    TripMapStatusBanner(
                      text: _errorText!,
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.92),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _titleController,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      labelText: isEditMode
                          ? 'عنوان مکان'
                          : 'عنوان اولیه (اختیاری)',
                      hintText: 'مثلاً: هتل، کافه، ساحل...',
                      helperText: isEditMode
                          ? 'عنوان جدید مکان را وارد کن.'
                          : 'این عنوان برای نمایش مارکر استفاده می‌شود.',
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
                  if (!isEditMode) ...[
                    const Text(
                      'تصاویر موقعیت مکانی',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _selectedImages.length) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
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

                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
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
                  ],
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
                          : Text(
                              isEditMode ? 'ذخیره تغییرات' : 'ثبت مکان',
                              style: const TextStyle(
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

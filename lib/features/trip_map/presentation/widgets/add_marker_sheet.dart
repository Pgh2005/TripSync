import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
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
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:tripsync/features/trip_map/data/models/marker_media_model.dart';

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

  // Images
  final List<File> _selectedImages = [];
  List<MarkerMediaModel> _existingImages = [];
  bool _isLoadingMedia = false;
  final ImagePicker _picker = ImagePicker();

  // Audio Recording
  final List<File> _selectedAudios = [];
  List<MarkerMediaModel> _existingAudios = [];
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    final marker = widget.initialMarker;
    if (marker != null) {
      _titleController.text = marker.title ?? '';
      _visibility = marker.visibility;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingMedia();
      });
    }
  }

  Future<void> _loadExistingMedia() async {
    if (widget.initialMarker == null) return;
    setState(() => _isLoadingMedia = true);
    try {
      final mediaService = ref.read(markerMediaServiceProvider);
      final markerId = widget.initialMarker!.id;

      final images = await mediaService.getMarkerMedia(
        markerId,
        MarkerMediaType.image,
      );
      final audios = await mediaService.getMarkerMedia(
        markerId,
        MarkerMediaType.audio,
      );

      if (!mounted) return;
      setState(() {
        _existingImages = images;
        _existingAudios = audios;
        _isLoadingMedia = false;
      });
    } catch (e) {
      debugPrint('Error loading existing media: $e');
      if (!mounted) return;
      setState(() => _isLoadingMedia = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _audioRecorder.dispose();
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

  Future<void> _deleteExistingImage(MarkerMediaModel media, int index) async {
    setState(() => _isSaving = true);
    try {
      final mediaService = ref.read(markerMediaServiceProvider);
      await mediaService.deleteSingleMedia(
        mediaId: media.id,
        storagePath: media.storagePath,
      );

      if (!mounted) return;
      setState(() {
        _existingImages.removeAt(index);
      });
      ref.invalidate(markerImagesProvider(widget.initialMarker!.id));
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = 'خطا در حذف عکس از سرور.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteExistingAudio(MarkerMediaModel media, int index) async {
    setState(() => _isSaving = true);
    try {
      final mediaService = ref.read(markerMediaServiceProvider);
      await mediaService.deleteSingleMedia(
        mediaId: media.id,
        storagePath: media.storagePath,
      );

      if (!mounted) return;
      setState(() {
        _existingAudios.removeAt(index);
      });
      ref.invalidate(markerAudiosProvider(widget.initialMarker!.id));
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = 'خطا در حذف صوت از سرور.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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

      String targetMarkerId;

      if (widget.isEditMode) {
        targetMarkerId = widget.initialMarker!.id;
        await repository.updateMarker(
          markerId: targetMarkerId,
          title: _titleController.text.trim(),
          visibility: _visibility,
        );
      } else {
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
        targetMarkerId = createdMarker.id;
      }

      if (_selectedImages.isNotEmpty) {
        for (int index = 0; index < _selectedImages.length; index++) {
          if (!mounted) return;
          setState(() {
            _loadingMessage =
                'آپلود تصویر ${index + 1} از ${_selectedImages.length}...';
          });

          await mediaService.uploadMedia(
            markerId: targetMarkerId,
            createdBy: user.id,
            file: _selectedImages[index],
            type: MarkerMediaType.image,
            visibility: _visibility,
          );
        }
      }

      if (_selectedAudios.isNotEmpty) {
        for (int index = 0; index < _selectedAudios.length; index++) {
          if (!mounted) return;
          setState(() {
            _loadingMessage =
                'آپلود صوت ${index + 1} از ${_selectedAudios.length}...';
          });

          await mediaService.uploadMedia(
            markerId: targetMarkerId,
            createdBy: user.id,
            file: _selectedAudios[index],
            type: MarkerMediaType.audio,
            visibility: _visibility,
          );
        }
      }

      ref.invalidate(tripMarkersProvider(widget.tripId));
      ref.invalidate(markerImagesProvider(targetMarkerId));
      ref.invalidate(markerAudiosProvider(targetMarkerId));

      if (!mounted) return;
      SnackbarHelper.showSuccess(
        context,
        widget.isEditMode
            ? 'تغییرات با موفقیت اعمال شد'
            : 'مکان با موفقیت ثبت شد',
      );

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

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        setState(() {
          _errorText = 'دسترسی میکروفون داده نشده است.';
        });
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/marker_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      setState(() {
        _errorText = null;
        _isRecording = true;
      });
    } catch (error) {
      setState(() {
        _errorText = 'شروع ضبط صدا ناموفق بود.';
        _isRecording = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();

      if (path == null || path.isEmpty) {
        setState(() {
          _isRecording = false;
          _errorText = 'فایل صوتی ذخیره نشد.';
        });
        return;
      }

      setState(() {
        _isRecording = false;
        _errorText = null;
        _selectedAudios.add(File(path));
      });
    } catch (error) {
      setState(() {
        _isRecording = false;
        _errorText = 'توقف ضبط صدا ناموفق بود.';
      });
    }
  }

  void _removeAudio(int index) {
    setState(() {
      _selectedAudios.removeAt(index);
    });
  }

  Widget _buildVisibilityCard({
    required MarkerVisibility value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _visibility == value;

    return InkWell(
      onTap: _isSaving
          ? null
          : () {
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
                        ? 'عنوان و سطح نمایش این مکان را ویرایش کن. همچنین می‌توانید رسانه‌های آن را مدیریت کنید.'
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
                    style: const TextStyle(color: AppColors.textDark),
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

                  // بخش تصاویر
                  const Text(
                    'تصاویر موقعیت مکانی',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_isLoadingMedia)
                    const Center(child: CircularProgressIndicator())
                  else
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount:
                            _existingImages.length + _selectedImages.length + 1,
                        itemBuilder: (context, index) {
                          if (index ==
                              _existingImages.length + _selectedImages.length) {
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

                          if (index < _existingImages.length) {
                            final media = _existingImages[index];
                            final remoteUrl = media.remoteUrl;
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child:
                                        remoteUrl != null &&
                                            remoteUrl.trim().isNotEmpty
                                        ? Image.network(
                                            remoteUrl,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 100,
                                            height: 100,
                                            color: Colors.grey.shade200,
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.broken_image_outlined,
                                              color: Colors.grey,
                                            ),
                                          ),
                                  ),
                                  if (!_isSaving)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () =>
                                            _deleteExistingImage(media, index),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.redAccent,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          child: const Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }

                          final localIndex = index - _existingImages.length;
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(
                                    _selectedImages[localIndex],
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
                                      onTap: () => _removeImage(localIndex),
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

                  // بخش صوت‌ها
                  const Text(
                    'صوت‌های موقعیت مکانی',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTapDown: _isSaving ? null : (_) => _startRecording(),
                    onTapUp: _isSaving ? null : (_) => _stopRecording(),
                    onTapCancel: _isSaving ? null : _stopRecording,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: _isRecording
                            ? Colors.redAccent.withValues(alpha: 0.12)
                            : AppColors.backgroundColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _isRecording
                              ? Colors.redAccent
                              : AppColors.borderColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isRecording ? Icons.mic : Icons.mic_none_outlined,
                            color: _isRecording
                                ? Colors.redAccent
                                : AppColors.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _isRecording
                                  ? 'در حال ضبط... انگشتت را رها کن تا ذخیره شود'
                                  : 'برای ضبط صدا لمس کن و نگه دار',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _isRecording
                                    ? Colors.redAccent
                                    : AppColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // نمایش صوت‌های قبلی موجود در سرور
                  if (_existingAudios.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'صوت‌های آپلود شده قبلی:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    Column(
                      children: List.generate(_existingAudios.length, (index) {
                        final media = _existingAudios[index];
                        return MarkerAudioPlayerRow(
                          audioSourceUrl: media.remoteUrl ?? '',
                          title: 'صوت ذخیره شده ${index + 1}',
                          accentColor: Colors.green,
                          onDelete: () => _deleteExistingAudio(media, index),
                          isDeleting: _isSaving,
                        );
                      }),
                    ),
                  ],

                  // نمایش صوت‌های جدید محلی آماده آپلود
                  if (_selectedAudios.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(top: 8, bottom: 8),
                      child: Text(
                        'صوت‌های آماده آپلود:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    Column(
                      children: List.generate(_selectedAudios.length, (index) {
                        final audioFile = _selectedAudios[index];
                        final fileName = audioFile.path.split('/').last;

                        return MarkerAudioPlayerRow(
                          audioSourcePath: audioFile.path,
                          title: fileName,
                          accentColor: AppColors.primaryColor,
                          onDelete: () => _removeAudio(index),
                          isDeleting: _isSaving,
                        );
                      }),
                    ),
                  ],
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
                      if (_isSaving || newValue == null) return;
                      setState(() {
                        _visibility = newValue;
                      });
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

/// ویجت اختصاصی پخش‌کننده صوت با اسلایدر و اطلاعات لحظه‌ای زمان
class MarkerAudioPlayerRow extends StatefulWidget {
  final String? audioSourceUrl;
  final String? audioSourcePath;
  final String title;
  final Color accentColor;
  final VoidCallback onDelete;
  final bool isDeleting;

  const MarkerAudioPlayerRow({
    super.key,
    this.audioSourceUrl,
    this.audioSourcePath,
    required this.title,
    required this.accentColor,
    required this.onDelete,
    required this.isDeleting,
  });

  @override
  State<MarkerAudioPlayerRow> createState() => _MarkerAudioPlayerRowState();
}

class _MarkerAudioPlayerRowState extends State<MarkerAudioPlayerRow> {
  late AudioPlayer _player;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      if (widget.audioSourceUrl != null && widget.audioSourceUrl!.isNotEmpty) {
        await _player.setUrl(widget.audioSourceUrl!);
      } else if (widget.audioSourcePath != null &&
          widget.audioSourcePath!.isNotEmpty) {
        await _player.setFilePath(widget.audioSourcePath!);
      }
    } catch (e) {
      debugPrint('Error loading audio track: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: StreamBuilder<PlayerState>(
        stream: _player.playerStateStream,
        builder: (context, playerStateSnapshot) {
          final playerState = playerStateSnapshot.data;
          final isPlaying = playerState?.playing ?? false;
          final processingState =
              playerState?.processingState ?? ProcessingState.idle;

          final isBuffering =
              processingState == ProcessingState.loading ||
              processingState == ProcessingState.buffering;

          return StreamBuilder<Duration>(
            stream: _player.positionStream,
            builder: (context, positionSnapshot) {
              final position = positionSnapshot.data ?? Duration.zero;

              return StreamBuilder<Duration?>(
                stream: _player.durationStream,
                builder: (context, durationSnapshot) {
                  final duration = durationSnapshot.data ?? Duration.zero;

                  final maxMilliseconds = duration.inMilliseconds > 0
                      ? duration.inMilliseconds.toDouble()
                      : 1.0;

                  final currentMilliseconds = position.inMilliseconds
                      .clamp(0, maxMilliseconds.toInt())
                      .toDouble();

                  return Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 42,
                            height: 42,
                            child: _isLoading || isBuffering
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : IconButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: _togglePlayback,
                                    icon: Icon(
                                      isPlaying
                                          ? Icons.pause_circle_filled_rounded
                                          : Icons.play_circle_fill_rounded,
                                      color: AppColors.primaryColor,
                                      size: 40,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${_formatDuration(position)} / '
                                  '${_formatDuration(duration)}',
                                  textDirection: TextDirection.ltr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: widget.isDeleting
                                ? null
                                : widget.onDelete,
                            icon: const Icon(
                              Icons.delete_rounded,
                              color: Colors.redAccent,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3.0,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6.0,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14.0,
                          ),
                        ),
                        child: Slider(
                          value: currentMilliseconds,
                          max: maxMilliseconds,
                          activeColor: AppColors.primaryColor,
                          inactiveColor: AppColors.borderColor,
                          onChanged: duration == Duration.zero
                              ? null
                              : (value) {
                                  _player.seek(
                                    Duration(milliseconds: value.round()),
                                  );
                                },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

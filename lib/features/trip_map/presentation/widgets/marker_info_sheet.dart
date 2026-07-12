import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripsync/core/utils/snackbar_helper.dart';
import 'package:tripsync/features/trip_map/presentation/providers/marker_media_service_provider.dart';
import 'package:tripsync/features/trip_map/presentation/widgets/add_marker_sheet.dart';
import 'package:tripsync/features/trip_map/presentation/widgets/trip_map_status_banner.dart';
import '../../../../core/enums/marker_visibility.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/trip_marker_models.dart';
import '../providers/trip_map_repository_provider.dart';
import '../providers/trip_markers_provider.dart';
import 'package:just_audio/just_audio.dart';

class MarkerInfoSheet extends ConsumerStatefulWidget {
  final TripMarkerModel marker;
  final String tripId;

  const MarkerInfoSheet({
    super.key,
    required this.marker,
    required this.tripId,
  });

  @override
  ConsumerState<MarkerInfoSheet> createState() => _MarkerInfoSheetState();
}

class _MarkerInfoSheetState extends ConsumerState<MarkerInfoSheet> {
  bool _isDeleting = false;
  String? _errorText;

  bool get _canDelete {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    return currentUserId != null && currentUserId == widget.marker.createdBy;
  }

  bool get _canEdit {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    return currentUserId != null && currentUserId == widget.marker.createdBy;
  }

  String get _visibilityLabel {
    switch (widget.marker.visibility) {
      case MarkerVisibility.ownerOnly:
        return 'فقط برای من';
      case MarkerVisibility.tripShared:
        return 'مشترک در سفر';
    }
  }

  String _mapDeleteError(Object error) {
    final raw = error.toString();

    if (raw.contains('SocketException') ||
        raw.contains('network') ||
        raw.contains('Network')) {
      return 'اتصال اینترنت برقرار نیست. حذف انجام نشد.';
    }

    if (raw.contains('row-level security') || raw.contains('42501')) {
      return 'اجازه حذف این مکان را نداری.';
    }

    return 'حذف مکان انجام نشد. دوباره تلاش کن.';
  }

  Future<void> _openEditMarkerSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddMarkerSheet(
        tripId: widget.tripId,
        point: LatLng(widget.marker.latitude, widget.marker.longitude),
        initialMarker: widget.marker,
      ),
    );

    if (!mounted || result != true) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _deleteMarker() async {
    if (_isDeleting || !_canDelete) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('حذف مکان'),
            content: const Text(
              'آیا مطمئن هستی که می‌خواهی این مارکر حذف شود؟ با حذف مارکر تمامی عکس‌های آن نیز حذف خواهند شد.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('انصراف'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isDeleting = true;
      _errorText = null;
    });

    try {
      final repository = ref.read(tripMapRepositoryProvider);
      await repository.deleteMarker(widget.marker.id);
      ref.invalidate(tripMarkersProvider(widget.tripId));

      if (!mounted) return;
      SnackbarHelper.showSuccess(context, 'مکان با موفقیت حذف شد');
      context.pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = _mapDeleteError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor ?? AppColors.textDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagesAsyncValue = ref.watch(markerImagesProvider(widget.marker.id));
    final audiosAsyncValue = ref.watch(markerAudiosProvider(widget.marker.id));
    final markerTitle = widget.marker.title?.isNotEmpty == true
        ? widget.marker.title!
        : 'بدون عنوان';

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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                  if (_errorText != null) ...[
                    TripMapStatusBanner(
                      text: _errorText!,
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.92),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.markercolor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          markerTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  imagesAsyncValue.when(
                    data: (urls) {
                      if (urls.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تصاویر ثبت‌شده',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: urls.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: GestureDetector(
                                    onTap: () => _showImagePreview(urls[index]),
                                    child: Hero(
                                      tag: urls[index],
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.network(
                                          urls[index],
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          loadingBuilder:
                                              (
                                                context,
                                                child,
                                                loadingProgress,
                                              ) {
                                                if (loadingProgress == null) {
                                                  return child;
                                                }
                                                return Container(
                                                  width: 120,
                                                  height: 120,
                                                  color:
                                                      AppColors.backgroundColor,
                                                  child: const Center(
                                                    child: SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                    ),
                                                  ),
                                                );
                                              },
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => Container(
                                                width: 120,
                                                height: 120,
                                                color:
                                                    AppColors.backgroundColor,
                                                child: const Icon(
                                                  Icons.broken_image_outlined,
                                                  color: AppColors.textMuted,
                                                ),
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, stack) => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'خطا در بارگذاری تصاویر مکان',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),

                  audiosAsyncValue.when(
                    data: (audios) {
                      final playableAudios = audios
                          .where(
                            (audio) =>
                                audio.remoteUrl != null &&
                                audio.remoteUrl!.trim().isNotEmpty,
                          )
                          .toList();

                      if (playableAudios.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'صداهای ثبت‌شده',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...List.generate(playableAudios.length, (index) {
                            final audio = playableAudios[index];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: MarkerAudioPlayer(
                                key: ValueKey(audio.id),
                                audioUrl: audio.remoteUrl!,
                                title: 'صدای ${index + 1}',
                              ),
                            );
                          }),
                          const SizedBox(height: 10),
                        ],
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, stackTrace) => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'خطا در بارگذاری صداهای مکان',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),

                  _buildInfoTile(
                    icon: Icons.visibility_rounded,
                    label: 'سطح نمایش مکان',
                    value: _visibilityLabel,
                    iconColor: AppColors.primaryColor,
                  ),
                  const SizedBox(height: 24),
                  if (_canEdit) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isDeleting ? null : _openEditMarkerSheet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('ویرایش مکان'),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_canDelete)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isDeleting ? null : _deleteMarker,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          foregroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: _isDeleting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.redAccent,
                                ),
                              )
                            : const Icon(Icons.delete_outline_rounded),
                        label: Text(_isDeleting ? 'در حال حذف...' : 'حذف مکان'),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: const Text(
                        'فقط ایجادکننده مارکر دسترسی حذف دارد.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
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

class MarkerAudioPlayer extends StatefulWidget {
  final String audioUrl;
  final String title;

  const MarkerAudioPlayer({
    super.key,
    required this.audioUrl,
    required this.title,
  });

  @override
  State<MarkerAudioPlayer> createState() => _MarkerAudioPlayerState();
}

// Audio Player
class _MarkerAudioPlayerState extends State<MarkerAudioPlayer> {
  late final AudioPlayer _player;

  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      await _player.setUrl(widget.audioUrl);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = false;
      });
    } catch (error) {
      debugPrint('Error loading marker audio: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _togglePlayback() async {
    if (_isLoading || _hasError) return;

    try {
      if (_player.playing) {
        await _player.pause();
        return;
      }

      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }

      await _player.play();
    } catch (error) {
      debugPrint('Error playing marker audio: $error');

      if (!mounted) return;

      setState(() {
        _hasError = true;
      });
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
        ),
        child: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'فایل صوتی قابل پخش نیست.',
                style: TextStyle(fontSize: 13, color: Colors.redAccent),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
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
                          const Icon(
                            Icons.graphic_eq_rounded,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                      Slider(
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

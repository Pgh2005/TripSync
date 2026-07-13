import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripsync/core/theme/app_colors.dart';
import 'package:tripsync/features/trip/data/models/trip_model.dart';
import 'package:tripsync/features/trip/data/services/trip_service.dart';
import 'package:tripsync/features/trip/presentation/widget/trip_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TripService _tripService = TripService();

  List<TripModel> _trips = [];
  bool _isLoading = true;
  String? _errorMessage; // متغیر جدید برای رهگیری خطاها
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadTrips();
  }

  Future<void> _loadProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .single();
      if (mounted) {
        setState(() => _userName = profile['full_name'] ?? '');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // تشخیص خطای عدم اتصال به شبکه
  String _mapErrorToMessage(Object error) {
    final raw = error.toString();
    if (raw.contains('SocketException') ||
        raw.contains('Failed host lookup') ||
        raw.contains('Network is unreachable') ||
        raw.contains('ClientException') ||
        raw.contains('connection')) {
      return 'اتصال اینترنت برقرار نیست. لطفاً شبکه خود را بررسی کن.';
    }
    return 'دریافت اطلاعات ناموفق بود. لطفاً دوباره تلاش کن.';
  }

  Future<void> _loadTrips() async {
    try {
      final trips = await _tripService.getUserTrips();
      if (mounted) {
        setState(() {
          _trips = trips;
          _errorMessage = null; // پاک کردن خطاهای قبلی در صورت موفقیت
        });
      }
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        setState(() {
          _errorMessage = _mapErrorToMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await _loadProfile();
    await _loadTrips();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primaryColor,
        child: CustomScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(), // فعال نگه‌داشتن اسکرول برای انجام رفرش حتی در حالت خطا
          slivers: [
            // ── SliverAppBar ──────────────────────────────────────
            SliverAppBar(
              expandedHeight: 100,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: _buildHeader(),
              ),
            ),

            // ── محتوا ─────────────────────────────────────────────
            _isLoading
                ? const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      24,
                      20,
                      MediaQuery.of(context).padding.bottom + 90,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildSectionTitle(),
                        const SizedBox(height: 16),
                        if (_errorMessage != null)
                          _buildErrorState() // نمایش وضعیت خطا
                        else if (_trips.isEmpty)
                          _buildEmptyState() // نمایش وضعیت خالی بودن واقعی لیست
                        else
                          ..._trips.map(
                            (trip) => TripCard(
                              trip: trip,
                              onTap: () async {
                                final result = await context.push(
                                  '/trip-detail',
                                  extra: trip,
                                );

                                if (result == true && mounted) {
                                  _refresh();
                                }
                              },
                            ),
                          ),
                      ]),
                    ),
                  ),
          ],
        ),
      ),

      // ── FAB ───────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push('/create-trip');

          if (result == true && mounted) {
            _refresh();
          }
        },
        backgroundColor: AppColors.primaryColor,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'سفر جدید',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  // ── هدر گرادیانت ─────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryColor, Color(0xFF1D4ED8)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _userName.isEmpty ? 'سلام 👋' : 'سلام $_userName 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'آماده سفر بعدی هستی؟',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: IconButton(
              onPressed: () {
                context.push('/profile');
              },
              icon: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── تیتر بخش + badge تعداد ───────────────────────────────────────
  Widget _buildSectionTitle() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'سفرهای من',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              letterSpacing: -0.3,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            final result = await context.push('/join-trip');

            if (result == true && mounted) {
              _refresh();
            }
          },
          icon: const Icon(
            Icons.group_add_rounded,
            size: 18,
            color: AppColors.primaryColor,
          ),
          label: const Text(
            'پیوستن',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            side: BorderSide(
              color: AppColors.primaryColor.withValues(alpha: 0.25),
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  // ── حالت خطا و قطعی شبکه ──────────────────────────────────────────
  Widget _buildErrorState() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.redAccent.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              size: 38,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'خطایی رخ داده است',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refresh,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 18,
              color: Colors.white,
            ),
            label: const Text('تلاش مجدد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── حالت خالی بودن واقعی لیست ──────────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.travel_explore_rounded,
              size: 38,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'هنوز سفری ثبت نشده!',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'اولین سفر گروهی خودت رو بساز',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

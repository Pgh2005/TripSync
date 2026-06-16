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
      setState(() => _userName = profile['full_name'] ?? '');
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _loadTrips() async {
    try {
      final trips = await _tripService.getUserTrips();
      setState(() => _trips = trips);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
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
                        if (_trips.isEmpty)
                          _buildEmptyState()
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
          // آواتار
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

        // if (_trips.isNotEmpty)
        //   Container(
        //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        //     decoration: BoxDecoration(
        //       color: AppColors.primaryColor.withValues(alpha: 0.08),
        //       borderRadius: BorderRadius.circular(20),
        //     ),
        //     child: Text(
        //       '${_trips.length} سفر',
        //       style: const TextStyle(
        //         fontSize: 12,
        //         fontWeight: FontWeight.w700,
        //         color: AppColors.primaryColor,
        //       ),
        //     ),
        //   ),
        const SizedBox(width: 10),

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

  // ── حالت خالی ────────────────────────────────────────────────────
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

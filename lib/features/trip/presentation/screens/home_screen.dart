import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  static const Color primaryColor = Color(0xFF2563EB);
  static const Color bgColor = Color(0xFFF8FAFF);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);

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
      final trips = await _tripService.getMyTrips();
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
      backgroundColor: bgColor,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: primaryColor,
        child: CustomScrollView(
          slivers: [
            // ── SliverAppBar ──────────────────────────────────────
            SliverAppBar(
              expandedHeight: 100,
              floating: false,
              pinned: true,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: borderColor),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: _buildHeader(),
              ),
            ),

            // ── محتوا ─────────────────────────────────────────────
            _isLoading
                ? const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: primaryColor),
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
                              onTap: () {
                                context.push('/trip-detail', extra: trip);
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
        backgroundColor: primaryColor,
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
          colors: [primaryColor, Color(0xFF1D4ED8)],
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
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  // ── تیتر بخش + badge تعداد ───────────────────────────────────────
  Widget _buildSectionTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'سفرهای من',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textDark,
            letterSpacing: -0.3,
          ),
        ),
        if (_trips.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_trips.length} سفر',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: primaryColor,
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
        border: Border.all(color: borderColor, width: 1),
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
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.travel_explore_rounded,
              size: 38,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'هنوز سفری ثبت نشده!',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'اولین سفر گروهی خودت رو بساز',
            style: TextStyle(fontSize: 13, color: textMuted, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

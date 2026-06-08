import 'package:flutter/material.dart';
import 'package:tripsync/features/trip/data/services/trip_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text('Home')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              try {
                await TripService().createTrip(
                  title: 'سفر رامسر',
                  destination: 'رامسر',
                  startDate: DateTime.now(),
                );

                debugPrint('TRIP CREATED');
              } catch (e) {
                debugPrint('ERROR: $e');
              }
            },
            child: const Text('تست ساخت سفر'),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:tripsync/features/trip/presentation/models/trip.dart';
// import 'package:tripsync/features/trip/presentation/widget/trip_card.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   static const Color primaryColor = Color(0xFF2563EB);
//   static const Color bgColor = Color(0xFFF8FAFF);
//   static const Color textDark = Color(0xFF0F172A);
//   static const Color textMuted = Color(0xFF64748B);

//   // TODO: از Supabase لود میشه
//   final List<Trip> _trips = [
//     Trip(
//       id: '1',
//       title: 'سفر به شمال',
//       destination: 'مازندران',
//       startDate: DateTime(2025, 7, 15),
//       endDate: DateTime(2025, 7, 20),
//       memberCount: 6,
//       status: TripStatus.confirmed,
//     ),
//     Trip(
//       id: '2',
//       title: 'کمپ کوهستان',
//       destination: 'دماوند',
//       startDate: DateTime(2025, 8, 3),
//       endDate: DateTime(2025, 8, 6),
//       memberCount: 4,
//       status: TripStatus.planning,
//     ),
//     Trip(
//       id: '3',
//       title: 'تور جنوب',
//       destination: 'کیش',
//       startDate: DateTime(2025, 4, 10),
//       endDate: DateTime(2025, 4, 14),
//       memberCount: 8,
//       status: TripStatus.completed,
//     ),
//   ];

//   // فیلتر فعال
//   TripStatus? _activeFilter;

//   List<Trip> get _filteredTrips {
//     if (_activeFilter == null) return _trips;
//     return _trips.where((t) => t.status == _activeFilter).toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         backgroundColor: bgColor,
//         body: CustomScrollView(
//           slivers: [
//             // ── AppBar اسکرول‌شونده ──────────────────────────────────
//             SliverAppBar(
//               expandedHeight: 190,
//               floating: false,
//               pinned: true,
//               backgroundColor: Colors.white,
//               surfaceTintColor: Colors.transparent,
//               elevation: 0,
//               flexibleSpace: FlexibleSpaceBar(
//                 background: _buildHeader(),
//                 collapseMode: CollapseMode.parallax,
//               ),
//               bottom: PreferredSize(
//                 preferredSize: const Size.fromHeight(56),
//                 child: _buildFilterBar(),
//               ),
//               titleSpacing: 0,
//             ),
//             // ── لیست سفرها ──────────────────────────────────────────
//             _filteredTrips.isEmpty
//                 ? SliverFillRemaining(child: _buildEmptyState())
//                 : SliverPadding(
//                     padding: EdgeInsets.fromLTRB(
//                       20,
//                       20,
//                       20,
//                       MediaQuery.of(context).padding.bottom + 90,
//                     ),
//                     sliver: SliverList(
//                       delegate: SliverChildBuilderDelegate(
//                         (context, index) => TripCard(
//                           trip: _filteredTrips[index],
//                           onTap: () {
//                             // TODO: context.push('/trip/${_filteredTrips[index].id}');
//                           },
//                         ),
//                         childCount: _filteredTrips.length,
//                       ),
//                     ),
//                   ),
//           ],
//         ),

//         // ── FAB ──────────────────────────────────────────────────────
//         floatingActionButton: _buildFAB(),
//       ),
//     );
//   }

//   // ── هدر با خوش‌آمدگویی ──────────────────────────────────────────
//   Widget _buildHeader() {
//     return Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [primaryColor, Color(0xFF1D4ED8)],
//           begin: Alignment.topRight,
//           end: Alignment.bottomLeft,
//         ),
//       ),
//       padding: EdgeInsets.fromLTRB(
//         20,
//         MediaQuery.of(context).padding.top + 16,
//         20,
//         16,
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Text(
//                   'سلام، علی 👋',
//                   style: TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.w800,
//                     color: Colors.white,
//                     letterSpacing: -0.3,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // آواتار
//           Container(
//             width: 48,
//             height: 48,
//             decoration: BoxDecoration(
//               color: Colors.white.withValues(alpha: 0.2),
//               borderRadius: BorderRadius.circular(14),
//               border: Border.all(
//                 color: Colors.white.withValues(alpha: 0.4),
//                 width: 1.5,
//               ),
//             ),
//             child: const Icon(
//               Icons.person_rounded,
//               color: Colors.white,
//               size: 26,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── فیلتر بار ───────────────────────────────────────────────────
//   Widget _buildFilterBar() {
//     final filters = [
//       (null, 'همه'),
//       (TripStatus.planning, 'برنامه‌ریزی'),
//       (TripStatus.confirmed, 'تأیید شده'),
//       (TripStatus.completed, 'تمام شده'),
//     ];

//     return Container(
//       height: 56,
//       color: Colors.white,
//       child: ListView.separated(
//         scrollDirection: Axis.horizontal,
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         itemCount: filters.length,
//         separatorBuilder: (_, _) => const SizedBox(width: 8),
//         itemBuilder: (context, index) {
//           final (status, label) = filters[index];
//           final isActive = _activeFilter == status;
//           return GestureDetector(
//             onTap: () => setState(() => _activeFilter = status),
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 200),
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               decoration: BoxDecoration(
//                 color: isActive ? primaryColor : const Color(0xFFF1F5F9),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Center(
//                 child: Text(
//                   label,
//                   style: TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w600,
//                     color: isActive ? Colors.white : textMuted,
//                   ),
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   // ── حالت خالی ───────────────────────────────────────────────────
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 80,
//             height: 80,
//             decoration: BoxDecoration(
//               color: primaryColor.withValues(alpha: 0.08),
//               borderRadius: BorderRadius.circular(24),
//             ),
//             child: const Icon(
//               Icons.travel_explore_rounded,
//               size: 40,
//               color: primaryColor,
//             ),
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             'هنوز سفری ثبت نشده!',
//             style: TextStyle(
//               fontSize: 17,
//               fontWeight: FontWeight.w700,
//               color: textDark,
//             ),
//           ),
//           const SizedBox(height: 6),
//           const Text(
//             'اولین سفر گروهیت رو بساز',
//             style: TextStyle(fontSize: 13, color: textMuted),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── دکمه ساخت سفر جدید ──────────────────────────────────────────
//   Widget _buildFAB() {
//     return FloatingActionButton.extended(
//       onPressed: () {
//         // TODO: context.push('/new-trip');
//       },
//       backgroundColor: primaryColor,
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       icon: const Icon(Icons.add_rounded, color: Colors.white),
//       label: const Text(
//         'سفر جدید',
//         style: TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.w700,
//           fontSize: 15,
//         ),
//       ),
//     );
//   }
// }

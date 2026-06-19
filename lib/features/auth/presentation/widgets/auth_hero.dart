import 'package:flutter/material.dart';
import 'package:tripsync/core/theme/app_colors.dart';

class AuthHero extends StatelessWidget {
  final double imageSize;

  const AuthHero({super.key, this.imageSize = 120});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/TripSyncLogo.png',
          width: imageSize,
          height: imageSize,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Icon(
            Icons.travel_explore_rounded,
            color: Colors.white,
            size: imageSize * 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite_border_rounded,
              color: AppColors.authPrimaryColor,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              'همراه سفرهای گروهی شما',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.taglineColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }
}

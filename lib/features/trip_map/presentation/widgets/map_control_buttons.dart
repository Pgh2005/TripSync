import 'package:flutter/material.dart';
import 'package:tripsync/core/utils/snackbar_helper.dart';

class MapControlButtons extends StatelessWidget {
  final VoidCallback onMyLocationPressed;

  const MapControlButtons({super.key, required this.onMyLocationPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // دکمه موقعیت من
          FloatingActionButton.small(
            heroTag: 'myLocation',
            backgroundColor: Colors.white,
            onPressed: onMyLocationPressed,
            child: const Icon(Icons.my_location, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          // دکمه راهنما
          FloatingActionButton.small(
            heroTag: 'helpButton',
            backgroundColor: Colors.white,
            onPressed: () {
              SnackbarHelper.showInfo(
                context,
                'برای ثبت مکان جدید، روی نقشه لمس طولانی انجام دهید',
              );
            },
            child: const Icon(Icons.help_outline, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class MapControlButtons extends StatelessWidget {
  final VoidCallback onMyLocationTap;
  final VoidCallback onHelpTap;

  const MapControlButtons({
    super.key,
    required this.onMyLocationTap,
    required this.onHelpTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'tripMap_myLocation',
          backgroundColor: Colors.white,
          onPressed: onMyLocationTap,
          child: const Icon(Icons.my_location_rounded, color: Colors.blue),
        ),
        const SizedBox(height: 10),
        FloatingActionButton.small(
          heroTag: 'tripMap_help',
          backgroundColor: Colors.white,
          onPressed: onHelpTap,
          child: const Icon(Icons.help_outline_rounded, color: Colors.blueGrey),
        ),
      ],
    );
  }
}

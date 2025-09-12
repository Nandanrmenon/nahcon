import 'package:flutter/material.dart';

class VideoInfoChip extends StatelessWidget {
  final String label;
  const VideoInfoChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}

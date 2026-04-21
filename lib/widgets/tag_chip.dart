// lib/widgets/tag_chip.dart
// Colored tag chip for displaying document tags

import 'package:flutter/material.dart';
import '../utils/theme.dart';

class TagChip extends StatelessWidget {
  final String tag;
  final bool small;

  const TagChip({super.key, required this.tag, this.small = false});

  @override
  Widget build(BuildContext context) {
    final color = DocNestTheme.tagColors[tag] ?? DocNestTheme.textSecondary;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(small ? 6 : 8),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: color,
          fontSize: small ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

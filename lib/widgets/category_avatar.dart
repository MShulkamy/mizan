import 'package:flutter/material.dart';

import '../data/models/category.dart';

/// Circular icon badge for a category, tinted with the category colour.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    super.key,
    required this.category,
    this.size = 44,
    this.filled = true,
  });

  final Category category;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled
            ? color.withValues(alpha: 0.16)
            : color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Icon(
        category.icon,
        size: size * 0.46,
        color: color,
      ),
    );
  }
}

/// A small coloured pill, e.g. for a category name or a status.
class TagPill extends StatelessWidget {
  const TagPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

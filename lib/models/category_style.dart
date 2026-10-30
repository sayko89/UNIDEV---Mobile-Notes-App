import 'package:flutter/material.dart';

import '../util/text.dart';

/// Colour and icon of a category, used for the round badges in lists, the calendar dots
/// and the timeline.
@immutable
class CategoryStyle {
  const CategoryStyle(this.color, this.icon);

  final Color color;
  final IconData icon;
}

const _known = <String, CategoryStyle>{
  'genel': CategoryStyle(Color(0xFF5B7C99), Icons.sticky_note_2_outlined),
  'iş': CategoryStyle(Color(0xFF3F6FB5), Icons.work_outline),
  'kişisel': CategoryStyle(Color(0xFFE07A8B), Icons.favorite_outline),
  'okul': CategoryStyle(Color(0xFFE39B32), Icons.school_outlined),
  'alişveriş': CategoryStyle(Color(0xFF6FAE5A), Icons.shopping_basket_outlined),
  'sağlik': CategoryStyle(Color(0xFFD9564A), Icons.favorite_border),
  'spor': CategoryStyle(Color(0xFF4FA59C), Icons.directions_run),
  'seyahat': CategoryStyle(Color(0xFF8C6BC9), Icons.flight_takeoff),
};

/// Categories the user creates get a colour from this list, picked by name so it stays the same.
const _palette = [
  Color(0xFF8C6BC9),
  Color(0xFF4FA59C),
  Color(0xFFD97B4F),
  Color(0xFF6FAE5A),
  Color(0xFFC9A227),
  Color(0xFFB5577E),
];

CategoryStyle categoryStyle(String category) {
  final key = foldForSearch(category.trim());
  final known = _known[key];
  if (known != null) return known;
  // A simple, platform-independent hash (String.hashCode is not guaranteed to be stable).
  var hash = 0;
  for (final unit in key.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return CategoryStyle(_palette[hash % _palette.length], Icons.label_outline);
}

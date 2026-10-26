import 'package:flutter/material.dart';

class CountingTheme {
  final String id;
  final String name;
  final IconData objectIcon;
  final Color background;
  final Color objectColor;
  final Color accent;

  const CountingTheme({
    required this.id,
    required this.name,
    required this.objectIcon,
    required this.background,
    required this.objectColor,
    required this.accent,
  });

  static const themes = [
    CountingTheme(
      id: 'garden',
      name: 'Garden',
      objectIcon: Icons.local_florist,
      background: Color(0xFFE8F5E9),
      objectColor: Color(0xFF388E3C),
      accent: Color(0xFF1B5E20),
    ),
    CountingTheme(
      id: 'night-sky',
      name: 'Night sky',
      objectIcon: Icons.star,
      background: Color(0xFFE8EAF6),
      objectColor: Color(0xFF5C6BC0),
      accent: Color(0xFF283593),
    ),
    CountingTheme(
      id: 'shapes',
      name: 'Shapes',
      objectIcon: Icons.circle,
      background: Color(0xFFFFF3E0),
      objectColor: Color(0xFFEF6C00),
      accent: Color(0xFFE65100),
    ),
  ];
}

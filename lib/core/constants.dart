import 'package:flutter/material.dart';

/// App-wide constants
class AppConstants {
  // Category names
  static const String categoryFood = 'Food';
  static const String categoryTransport = 'Transport';
  static const String categoryStudy = 'Study';
  static const String categoryEntertainment = 'Entertainment';
  static const String categoryRent = 'Rent';
  static const String categoryOther = 'Other';
  
  static const List<String> categories = [
    categoryFood,
    categoryTransport,
    categoryStudy,
    categoryEntertainment,
    categoryRent,
    categoryOther,
  ];
  
  // Category icons
  static const Map<String, IconData> categoryIcons = {
    categoryFood: Icons.restaurant,
    categoryTransport: Icons.directions_bus,
    categoryStudy: Icons.school,
    categoryEntertainment: Icons.movie,
    categoryRent: Icons.home,
    categoryOther: Icons.more_horiz,
  };
  
  // Category colors
  static const Map<String, Color> categoryColors = {
    categoryFood: Color(0xFFFF6B6B),
    categoryTransport: Color(0xFF4ECDC4),
    categoryStudy: Color(0xFF45B7D1),
    categoryEntertainment: Color(0xFFFFBE0B),
    categoryRent: Color(0xFF95E1D3),
    categoryOther: Color(0xFFB8B8B8),
  };
}


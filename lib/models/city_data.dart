/// City consumption data model
class CityData {
  final String name;
  final String province;  // State for US cities

  // Monthly average consumption by category (Unit: USD)
  final double rentLow;      // Rent (Low)
  final double rentMid;      // Rent (Mid)
  final double rentHigh;     // Rent (High)

  final double foodLow;      // Food (Low)
  final double foodMid;      // Food (Mid)
  final double foodHigh;     // Food (High)

  final double transportLow;  // Transport (Low)
  final double transportMid;  // Transport (Mid)
  final double transportHigh; // Transport (High)

  final double studyLow;      // Study (Low)
  final double studyMid;      // Study (Mid)
  final double studyHigh;     // Study (High)

  final double entertainmentLow;  // Entertainment (Low)
  final double entertainmentMid;  // Entertainment (Mid)
  final double entertainmentHigh; // Entertainment (High)

  final double otherLow;      // Other (Low)
  final double otherMid;      // Other (Mid)
  final double otherHigh;     // Other (High)

  const CityData({
    required this.name,
    required this.province,
    required this.rentLow,
    required this.rentMid,
    required this.rentHigh,
    required this.foodLow,
    required this.foodMid,
    required this.foodHigh,
    required this.transportLow,
    required this.transportMid,
    required this.transportHigh,
    required this.studyLow,
    required this.studyMid,
    required this.studyHigh,
    required this.entertainmentLow,
    required this.entertainmentMid,
    required this.entertainmentHigh,
    required this.otherLow,
    required this.otherMid,
    required this.otherHigh,
  });

  /// Get consumption amount for category and lifestyle
  double getCategoryAmount(String category, LifestyleLevel level) {
    switch (category) {
      case 'Rent':
        return level == LifestyleLevel.frugal
            ? rentLow
            : level == LifestyleLevel.moderate
                ? rentMid
                : rentHigh;
      case 'Food':
        return level == LifestyleLevel.frugal
            ? foodLow
            : level == LifestyleLevel.moderate
                ? foodMid
                : foodHigh;
      case 'Transport':
        return level == LifestyleLevel.frugal
            ? transportLow
            : level == LifestyleLevel.moderate
                ? transportMid
                : transportHigh;
      case 'Study':
        return level == LifestyleLevel.frugal
            ? studyLow
            : level == LifestyleLevel.moderate
                ? studyMid
                : studyHigh;
      case 'Entertainment':
        return level == LifestyleLevel.frugal
            ? entertainmentLow
            : level == LifestyleLevel.moderate
                ? entertainmentMid
                : entertainmentHigh;
      case 'Other':
        return level == LifestyleLevel.frugal
            ? otherLow
            : level == LifestyleLevel.moderate
                ? otherMid
                : otherHigh;
      default:
        return 0;
    }
  }

  /// Get total budget
  double getTotalBudget(LifestyleLevel level) {
    return getCategoryAmount('Rent', level) +
        getCategoryAmount('Food', level) +
        getCategoryAmount('Transport', level) +
        getCategoryAmount('Study', level) +
        getCategoryAmount('Entertainment', level) +
        getCategoryAmount('Other', level);
  }
}

/// LifestyleLevel
enum LifestyleLevel {
  frugal,    // Frugal
  moderate,  // Moderate
  comfortable // Comfortable
}

extension LifestyleLevelExtension on LifestyleLevel {
  String get displayName {
    switch (this) {
      case LifestyleLevel.frugal:
        return 'Frugal';
      case LifestyleLevel.moderate:
        return 'Moderate';
      case LifestyleLevel.comfortable:
        return 'Comfortable';
    }
  }

  String get description {
    switch (this) {
      case LifestyleLevel.frugal:
        return 'Focus on saving, reasonably control spending';
      case LifestyleLevel.moderate:
        return 'Balanced consumption, moderately enjoy life';
      case LifestyleLevel.comfortable:
        return 'Pursue quality, enjoy comfortable life';
    }
  }
}


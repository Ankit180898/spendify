import 'package:flutter/material.dart';

enum HealthLevel { poor, fair, good, great, excellent }

class HealthScore {
  final int total;
  final int savingsScore;
  final int budgetScore;
  final int goalScore;
  final int consistencyScore;
  final DateTime computedAt;

  const HealthScore({
    required this.total,
    required this.savingsScore,
    required this.budgetScore,
    required this.goalScore,
    required this.consistencyScore,
    required this.computedAt,
  });

  HealthLevel get level {
    if (total >= 81) return HealthLevel.excellent;
    if (total >= 66) return HealthLevel.great;
    if (total >= 46) return HealthLevel.good;
    if (total >= 26) return HealthLevel.fair;
    return HealthLevel.poor;
  }

  String get levelLabel {
    switch (level) {
      case HealthLevel.excellent: return 'Excellent';
      case HealthLevel.great:     return 'Great';
      case HealthLevel.good:      return 'Good';
      case HealthLevel.fair:      return 'Fair';
      case HealthLevel.poor:      return 'Poor';
    }
  }

  Color get levelColor {
    switch (level) {
      case HealthLevel.excellent: return const Color(0xFF8552FF);
      case HealthLevel.great:     return const Color(0xFF00C896);
      case HealthLevel.good:      return const Color(0xFFFFB300);
      case HealthLevel.fair:      return const Color(0xFFFF7849);
      case HealthLevel.poor:      return const Color(0xFFFF5370);
    }
  }

  Map<String, dynamic> toJson() => {
        'total': total,
        'savings': savingsScore,
        'budget': budgetScore,
        'goal': goalScore,
        'consistency': consistencyScore,
        'ts': computedAt.toIso8601String(),
      };

  factory HealthScore.fromJson(Map<String, dynamic> json) => HealthScore(
        total: json['total'] as int,
        savingsScore: json['savings'] as int,
        budgetScore: json['budget'] as int,
        goalScore: json['goal'] as int,
        consistencyScore: json['consistency'] as int,
        computedAt: DateTime.parse(json['ts'] as String),
      );
}

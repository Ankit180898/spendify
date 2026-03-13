class UserProfile {
  final String userId;
  final String currency;
  final String currencySymbol;
  final String occupation;
  final double monthlyBudget;
  final List<String> selectedCategories;
  final bool onboardingComplete;

  const UserProfile({
    required this.userId,
    required this.currency,
    required this.currencySymbol,
    required this.occupation,
    required this.monthlyBudget,
    required this.selectedCategories,
    required this.onboardingComplete,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String,
      currency: json['currency'] as String? ?? 'INR',
      currencySymbol: json['currency_symbol'] as String? ?? '₹',
      occupation: json['occupation'] as String? ?? '',
      monthlyBudget: (json['monthly_budget'] as num?)?.toDouble() ?? 0.0,
      selectedCategories: List<String>.from(json['selected_categories'] ?? []),
      onboardingComplete: json['onboarding_complete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'currency': currency,
        'currency_symbol': currencySymbol,
        'occupation': occupation,
        'monthly_budget': monthlyBudget,
        'selected_categories': selectedCategories,
        'onboarding_complete': onboardingComplete,
      };
}

import 'package:flutter/material.dart';

/// Rendered off-screen by home_widget's renderFlutterWidget and saved as a
/// PNG snapshot that the Android/iOS native widget displays as an image.
/// Must be completely self-contained — no Providers, no BuildContext look-ups.
class SpendifyWidgetPreview extends StatelessWidget {
  final String monthSpent;
  final String subtitle;
  final double budgetPct;
  final bool hasBudget;

  const SpendifyWidgetPreview({
    required this.monthSpent,
    required this.subtitle,
    required this.budgetPct,
    required this.hasBudget,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 350,
      height: 175,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF9B6BFF), Color(0xFF6B35EE)],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8552FF).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Stack(
            children: [
              // Decorative money emoji — top right
              const Positioned(
                top: -4,
                right: -4,
                child: Text('💸', style: TextStyle(fontSize: 52)),
              ),

              // Main content column
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App name
                  Text(
                    'Spendify',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Spending amount
                  Text(
                    monthSpent,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 5),

                  // Subtitle
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const Spacer(),

                  // Progress bar
                  if (hasBudget) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: budgetPct.clamp(0.0, 1.0),
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFFB300),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ] else ...[
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

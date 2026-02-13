import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette - "Midnight Intelligence"
  static const Color midnightBlue = Color(0xFF0D0F1F); // #0D0F1F
  static const Color deepSpace = Color(0xFF161B33);   // #161B33
  static const Color vibrantTeal = Color(0xFF00D4FF); // #00D4FF
  static const Color softElectric = Color(0xFF4D8BFF); // #4D8BFF
  
  // Accents
  static const Color highlightGold = Color(0xFFFFD700);
  static const Color errorRed = Color(0xFFFF4D4D);
  static const Color successGreen = Color(0xFF00C853);

  // Neutral
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color slateGray = Color(0xFF707070);
  static const Color lightGray = Color(0xFFF5F5F7);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [midnightBlue, deepSpace],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tealGradient = LinearGradient(
    colors: [vibrantTeal, softElectric],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

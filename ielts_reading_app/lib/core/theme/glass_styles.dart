import 'package:flutter/material.dart';

class GlassStyles {
  // Brand colors
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color secondaryGreen = Color(0xFF34D399);
  
  // Gradients for Mesh Scaffolds
  static const LinearGradient lightMeshGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFECFDF5), 
      Color(0xFFF8FAFC), 
      Color(0xFFD1FAE5), 
    ],
  );
  
  static const LinearGradient darkMeshGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF022C22),
      Color(0xFF0F172A),
      Color(0xFF064E3B),
    ],
  );

  static const double blurSigma = 16.0;
  static const BorderRadius defaultRadius = BorderRadius.all(Radius.circular(24.0));
  
  static Color glassColorLight = Colors.white.withOpacity(0.6);
  static Color glassColorDark = const Color(0xFF1E293B).withOpacity(0.4); 
  
  static Border glassBorderLight = Border.all(color: Colors.white.withOpacity(0.8), width: 1.5);
  static Border glassBorderDark = Border.all(color: Colors.white.withOpacity(0.15), width: 1.0);
}

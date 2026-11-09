import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Visual da Área do Cliente. Para mudar a identidade da loja, troque [marca].
class ClienteTema {
  static const Color marca = Color(0xFFD81B60); // destaque: botões, preços, selos
  static const Color marcaEscura = Color(0xFF8E0E3F);
  static const Color texto = Color(0xFF1C1B1F);
  static const Color suave = Color(0xFF6B6B76);
  static const Color fundo = Color(0xFFF6F6F8);

  static ThemeData get theme {
    final base = ColorScheme.fromSeed(seedColor: marca, primary: marca, surface: Colors.white);
    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: fundo,
      textTheme: GoogleFonts.poppinsTextTheme().apply(bodyColor: texto, displayColor: texto),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: texto,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: texto),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: marca,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: marca, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: marca.withValues(alpha: 0.12),
        labelTextStyle: WidgetStatePropertyAll(GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

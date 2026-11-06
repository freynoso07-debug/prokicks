import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Identidad visual de PROKICKS: blanco, negro y detalles en verde eléctrico
/// y naranja. Títulos en Barlow Condensed (deportiva), texto en Inter.
class Tema {
  static const Color negro = Color(0xFF0B0B0B);
  static const Color verde = Color(0xFFC6FF00);
  static const Color naranja = Color(0xFFFF5A1F);
  static const Color grisFondo = Color(0xFFF4F4F4);
  static const Color grisBorde = Color(0xFFE2E2E2);
  static const Color grisTexto = Color(0xFF6B6B6B);
  static const Color rojo = Color(0xFFD32F2F);
  static const Color verdeOk = Color(0xFF2E7D32);

  /// Estilo para títulos grandes (condensado, itálica, bien pesado).
  static TextStyle titulo(double tamanio, {Color color = negro}) {
    return GoogleFonts.barlowCondensed(
      fontSize: tamanio,
      fontWeight: FontWeight.w800,
      fontStyle: FontStyle.italic,
      height: 0.95,
      letterSpacing: 0.5,
      color: color,
    );
  }

  /// Etiquetas chicas en mayúsculas (marca, secciones del panel, etc.).
  static TextStyle etiqueta({Color color = grisTexto, double tamanio = 12}) {
    return GoogleFonts.inter(
      fontSize: tamanio,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
      color: color,
    );
  }

  static ThemeData get claro {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: negro,
        primary: negro,
        onPrimary: Colors.white,
        secondary: verde,
        onSecondary: negro,
        tertiary: naranja,
        error: rojo,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
    );

    final forma = RoundedRectangleBorder(borderRadius: BorderRadius.circular(4));

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: negro,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: negro,
          foregroundColor: Colors.white,
          shape: forma,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: negro,
          side: const BorderSide(color: negro),
          shape: forma,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: negro),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: negro, width: 2),
        ),
        isDense: true,
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      dividerTheme: const DividerThemeData(color: grisBorde, space: 1),
    );
  }
}

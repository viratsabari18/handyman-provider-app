import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handyman_provider_flutter/utils/colors.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:nb_utils/nb_utils.dart';

class AppTheme {
  AppTheme._();

  // 🔴 RED
  static const Color primaryRed = Color(0xFFDB0008);

  // 🟡 YELLOW
  static const Color secondaryYellow = Color(0xFFFFBC0D);

  // ⚪ WHITE
  static const Color scaffoldWhite = Color(0xFFFEFFFF);

  // ================= LIGHT THEME =================

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    primaryColor: primaryRed,

    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryRed,
    ).copyWith(
      primary: primaryRed,
      secondary: secondaryYellow,
      surface: scaffoldWhite,
    ),

    scaffoldBackgroundColor: scaffoldWhite,

    fontFamily: GoogleFonts.inter().fontFamily,
    textTheme: GoogleFonts.interTextTheme(),

    iconTheme: IconThemeData(color: Colors.black87),

    appBarTheme: AppBarTheme(
      backgroundColor: primaryRed,
      foregroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: primaryRed,
        statusBarIconBrightness: Brightness.light,
      ),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: scaffoldWhite,
      selectedItemColor: primaryRed,
      unselectedItemColor: Colors.grey,
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scaffoldWhite,
      indicatorColor: primaryRed.withOpacity(0.15),
      labelTextStyle: WidgetStateProperty.all(
        primaryTextStyle(size: 12),
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: secondaryYellow,
      foregroundColor: Colors.black,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryRed,
      ),
    ),

    checkboxTheme: CheckboxThemeData(
      checkColor: WidgetStateProperty.all(Colors.white),
      fillColor: WidgetStateProperty.all(primaryRed),
    ),

    cardColor: Colors.white,
    dividerColor: Colors.grey.shade300,

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: radiusOnly(
          topLeft: defaultRadius,
          topRight: defaultRadius,
        ),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: dialogShape(),
    ),

    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  // ================= DARK THEME =================

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,

    primaryColor: primaryRed,

    colorScheme: ColorScheme.dark(
      primary: primaryRed,
      secondary: secondaryYellow,
      surface: Colors.black,
    ),

    scaffoldBackgroundColor: Colors.black,

    fontFamily: GoogleFonts.inter().fontFamily,
    textTheme: GoogleFonts.interTextTheme(),

    iconTheme: IconThemeData(color: Colors.white),

    appBarTheme: AppBarTheme(
      backgroundColor: primaryRed,
      foregroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: primaryRed,
        statusBarIconBrightness: Brightness.light,
      ),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.black,
      selectedItemColor: secondaryYellow,
      unselectedItemColor: Colors.white60,
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.black,
      indicatorColor: secondaryYellow.withOpacity(0.2),
      labelTextStyle: WidgetStateProperty.all(
        primaryTextStyle(size: 12, color: Colors.white),
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: secondaryYellow,
      foregroundColor: Colors.black,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: secondaryYellow,
      ),
    ),

    checkboxTheme: CheckboxThemeData(
      checkColor: WidgetStateProperty.all(Colors.white),
      fillColor: WidgetStateProperty.all(primaryRed),
    ),

    cardColor: Colors.grey.shade900,
    dividerColor: Colors.grey.shade700,

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: radiusOnly(
          topLeft: defaultRadius,
          topRight: defaultRadius,
        ),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: Colors.grey.shade900,
      surfaceTintColor: Colors.transparent,
      shape: dialogShape(),
    ),

    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
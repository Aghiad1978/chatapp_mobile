import 'package:chatapp/Theme/app_colors.dart';
import 'package:flutter/material.dart';

ThemeData theme1 = ThemeData(
  scaffoldBackgroundColor: AppColors.backGroundColor,
  textTheme: TextTheme(
    displayMedium: TextStyle(
      color: AppColors.writtingColor,
      letterSpacing: 1.25,
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      textStyle: TextStyle(letterSpacing: 2, fontSize: 16),
      backgroundColor: AppColors.button2,
      foregroundColor: AppColors.writtingColor,
      minimumSize: Size(0, 64),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
);

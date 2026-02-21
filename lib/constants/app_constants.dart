import 'package:flutter/material.dart';

class AppColors {
  static const primary    = Color(0xFF1565C0); // น้ำเงินเข้ม
  static const high       = Color(0xFFD32F2F); // แดง
  static const medium     = Color(0xFFF57F17); // เหลือง
  static const low        = Color(0xFF2E7D32); // เขียว
  static const background = Color(0xFFF5F5F5);
}

class AppStrings {
  static const appName = 'Election Watch';
}

Color severityColor(String severity) {
  switch (severity) {
    case 'High':   return AppColors.high;
    case 'Medium': return AppColors.medium;
    case 'Low':    return AppColors.low;
    default:       return Colors.grey;
  }
}

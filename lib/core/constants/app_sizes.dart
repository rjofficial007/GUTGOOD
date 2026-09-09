import 'package:flutter/material.dart';
import 'package:gutgood/core/utils/responsive.dart';

class AppSizes {
  AppSizes._();

  // Base Padding & Margins
  static double get p2 => 2.0.w;
  static double get p4 => 4.0.w;
  static double get p6 => 6.0.w;
  static double get p8 => 8.0.w;
  static double get p10 => 10.0.w;
  static double get p12 => 12.0.w;
  static double get p13 => 13.0.w;
  static double get p14 => 14.0.w;
  static double get p16 => 16.0.w;
  static double get p18 => 18.0.w;
  static double get p20 => 20.0.w;
  static double get p24 => 24.0.w;
  static double get p32 => 32.0.w;
  static double get p36 => 36.0.w;
  static double get p40 => 40.0.w;
  static double get p44 => 44.0.w;
  static double get p56 => 56.0.w;
  static double get p64 => 64.0.w;
  static double get p100 => 100.0.w;
  static double get p120 => 120.0.w;

  // Border Radius
  static double get r4 => 4.0.w;
  static double get r8 => 8.0.w;
  static double get r12 => 12.0.w;
  static double get r14 => 14.0.w;
  static double get r16 => 16.0.w;
  static double get r18 => 18.0.w;
  static double get r20 => 20.0.w;
  static double get r24 => 24.0.w;
  static double get r28 => 28.0.w;
  static double get r32 => 32.0.w;
  static double get r100 => 108.0.w;

  // Icon Sizes
  static double get icon12 => 12.0.w;
  static double get icon14 => 14.0.w;
  static double get icon16 => 16.0.w;
  static double get icon18 => 18.0.w;
  static double get icon20 => 20.0.w;
  static double get icon24 => 24.0.w;
  static double get icon28 => 28.0.w;
  static double get icon32 => 32.0.w;
  static double get icon40 => 40.0.w;
  static double get icon44 => 44.0.w;
  static double get icon48 => 48.0.w;

  static double get icon60 => 60.0.w;

  // Text Sizes (sp)
  static double get s8 => 8.0.sp;
  static double get s9 => 9.0.sp;
  static double get s10 => 10.0.sp;
  static double get s11 => 11.0.sp;
  static double get s12 => 12.0.sp;
  static double get s13 => 13.0.sp;
  static double get s14 => 14.0.sp;
  static double get s15 => 15.0.sp;
  static double get s16 => 16.0.sp;
  static double get s18 => 18.0.sp;
  static double get s20 => 20.0.sp;
  static double get s22 => 22.0.sp;
  static double get s24 => 24.0.sp;

  static double get s40 => 40.0.sp;
  static double get s120 => 120.0.sp;

  // Misc Heights/Widths
  static double get w100 => 100.0.w;
  static double get w140 => 140.0.w;
  static double get w300 => 300.0.w;
  static double get w52 => 52.0.w;

  static double get w80 => 80.0.w;
  static double get w42 => 42.0.w;
}

class Gap {
  const Gap._();

  static Widget get w2 => SizedBox(width: 2.0.w);
  static Widget get w4 => SizedBox(width: 4.0.w);
  static Widget get w6 => SizedBox(width: 6.0.w);
  static Widget get w8 => SizedBox(width: 8.0.w);
  static Widget get w10 => SizedBox(width: 10.0.w);
  static Widget get w12 => SizedBox(width: 12.0.w);
  static Widget get w14 => SizedBox(width: 14.0.w);
  static Widget get w16 => SizedBox(width: 16.0.w);
  static Widget get w20 => SizedBox(width: 20.0.w);
  static Widget get w48 => SizedBox(width: 48.0.w);

  static Widget get h2 => SizedBox(height: 2.0.h);
  static Widget get h4 => SizedBox(height: 4.0.h);
  static Widget get h6 => SizedBox(height: 6.0.h);
  static Widget get h8 => SizedBox(height: 8.0.h);
  static Widget get h10 => SizedBox(height: 10.0.h);
  static Widget get h12 => SizedBox(height: 12.0.h);
  static Widget get h14 => SizedBox(height: 14.0.h);
  static Widget get h16 => SizedBox(height: 16.0.h);
  static Widget get h20 => SizedBox(height: 20.0.h);
  static Widget get h24 => SizedBox(height: 24.0.h);
  static Widget get h32 => SizedBox(height: 32.0.h);
  static Widget get h40 => SizedBox(height: 40.0.h);
  static Widget get h48 => SizedBox(height: 48.0.h);
  static Widget get h64 => SizedBox(height: 64.0.h);
}

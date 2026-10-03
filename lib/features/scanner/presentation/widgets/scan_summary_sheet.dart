import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/gut_score_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_button.dart';
import 'package:gutgood/features/scanner/presentation/providers/scanner_notifier.dart';
import 'package:gutgood/features/scanner/presentation/widgets/scan_detail_sections.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';


part 'scan_summary_sheet_state.dart';
part 'scan_health_factor.dart';
part 'scan_factor_row.dart';

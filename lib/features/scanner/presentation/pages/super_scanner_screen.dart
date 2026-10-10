import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_assets.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/barcode_validator.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_button.dart';
import 'package:gutgood/features/auth/presentation/utils/quota_guard.dart';
import 'package:gutgood/features/scanner/presentation/providers/scanner_notifier.dart';
import 'package:gutgood/features/scanner/presentation/utils/scanner_capture_readiness.dart';
import 'package:gutgood/features/scanner/presentation/widgets/scan_summary_sheet.dart';
import 'package:gutgood/features/scanner/presentation/widgets/scanner_overlay.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


part 'super_scanner_state.dart';
part 'scanner_camera_preview.dart';
part 'scanner_top_bar.dart';
part 'scanner_icon_button.dart';
part 'scanner_bottom_dock.dart';
part 'scanner_permission_overlay.dart';
part 'scanner_shutter_button.dart';

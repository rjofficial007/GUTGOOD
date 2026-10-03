import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/models/scans/off_product.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/product_details/presentation/pages/additive_level_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// In-sheet "smooth-app style" fact sheet: everything GutGood knows about the
// scanned product from Open Food Facts, packed into tappable, expandable
// sections so the sheet stays scannable ("show details if available" —
// sections with no data simply don't render).
//
// Used by [ScanSummarySheet] below the Positives/Negatives analysis, above
// the action CTA. All fields beyond the summary set are optional, so scans
// cached before this feature degrade gracefully.

part 'scan_product_details.dart';
part 'scan_detail_tile.dart';
part 'scan_detail_card.dart';
part 'scan_scores_body.dart';
part 'scan_nutrition_facts_body.dart';
part 'scan_ingredients_body.dart';
part 'scan_additives_body.dart';
part 'scan_allergens_body.dart';
part 'scan_labels_body.dart';
part 'scan_serving_toggle.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/insight_theme.dart';
import 'package:gutgood/core/utils/insight_values.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/pages/better_swaps_screen.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_feed/insight_feed_derivations.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_feed/insight_ui_kit.dart';
import 'package:gutgood/features/insights/presentation/widgets/occurrence_tile.dart';
import 'package:gutgood/features/insights/presentation/widgets/why_score_sheet.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

// Top Healing / Top Trigger detail screen.

part 'highlight_detail_page.dart';
part 'highlight_detail_healing_sections.dart';
part 'highlight_detail_trigger_sections.dart';
part 'highlight_detail_helpers.dart';
part 'highlight_contributing_card.dart';
part 'highlight_box.dart';
part 'highlight_trigger_stat_col.dart';
part 'aligned_day_labels_row.dart';

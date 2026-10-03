import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_assets.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/insight_values.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/insights/presentation/widgets/arc_pattern_card.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/bento_data.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/bento_widgets.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/pattern_style.dart';
import 'package:gutgood/features/insights/presentation/widgets/gut_score_card.dart';
import 'package:gutgood/features/insights/presentation/widgets/why_score_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Screen 01 — the bento Insights feed.
//
// Replaces `InsightDiscoverSliver` as the Insights tab body. Same data in
// (`AIInsight` + prioritized `BodyPattern`s), v4 bento presentation out.

part 'insight_bento_feed_screen.dart';
part 'insight_bento_learning.dart';
part 'insight_bento_learning_card.dart';
part 'insight_bento_discovery_card.dart';
part 'insight_bento_highlight_card.dart';
part 'insight_bento_chart_painters.dart';

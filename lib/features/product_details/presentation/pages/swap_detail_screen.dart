import 'package:flutter/material.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/features/insights/presentation/pages/swap_detail_screen.dart' as shared;

/// Keeps existing scan/chat routes while sharing the complete swap detail UI.
class SwapDetailScreen extends StatelessWidget {
  const SwapDetailScreen({super.key, required this.swap});
  final ProductSwap swap;

  @override
  Widget build(BuildContext context) => shared.SwapDetailScreen(alternative: swap.toAlternative());
}

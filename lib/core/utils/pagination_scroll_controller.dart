import 'package:flutter/material.dart';

/// Mixin for [StatefulWidget]s that manages scroll listener lifecycle and triggers [onFetchMore]
/// when scroll approaches the bottom edge.
mixin PaginationScrollMixin<T extends StatefulWidget> on State<T> {
  late final ScrollController scrollController;

  /// Callback executed when scroll position crosses threshold.
  void onFetchMore();

  /// Distance from bottom edge (in pixels) at which [onFetchMore] is triggered.
  double get fetchThresholdPixels => 200.0;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController()..addListener(_handleScrollListener);
  }

  void _handleScrollListener() {
    if (!scrollController.hasClients) return;
    final maxExtent = scrollController.position.maxScrollExtent;
    final currentOffset = scrollController.position.pixels;
    if (currentOffset >= maxExtent - fetchThresholdPixels) {
      onFetchMore();
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(_handleScrollListener);
    scrollController.dispose();
    super.dispose();
  }
}

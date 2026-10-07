import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/features/chat/presentation/widgets/chat_components.dart';

Widget chat({
  required ScrollController controller,
  required GlobalKey anchorKey,
  required double promptHeight,
  required double responseHeight,
  double composerHeight = 64,
  double priorTurnHeight = 0,
  int historyCount = 30,
}) => MaterialApp(
  home: Scaffold(
    appBar: AppBar(title: const Text('Chat')),
    body: Column(
      children: [
        Expanded(
          child: CustomScrollView(
            controller: controller,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    SliverList.builder(itemCount: historyCount, itemBuilder: (_, i) => SizedBox(height: 80 + (i % 3) * 24)),
                    SliverToBoxAdapter(child: SizedBox(height: priorTurnHeight)),
                    const SliverToBoxAdapter(child: SizedBox(height: 32, child: Text('Today'))),
                    ChatTurnSliver(
                      anchorKey: anchorKey,
                      children: [
                        SizedBox(key: const ValueKey('prompt'), height: promptHeight, child: const Text('User prompt or photo')),
                        SizedBox(key: const ValueKey('response'), height: responseHeight, child: const Text('AI response')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: composerHeight),
      ],
    ),
  ),
);

void main() {
  testWidgets('the first prompt aligns below the App Bar with its date heading above it', (tester) async {
    final controller = ScrollController();
    final anchorKey = GlobalKey();
    addTearDown(controller.dispose);
    await tester.pumpWidget(chat(controller: controller, anchorKey: anchorKey, promptHeight: 60, responseHeight: 48, historyCount: 0));
    await Scrollable.ensureVisible(anchorKey.currentContext!, alignment: 0);
    await tester.pumpAndSettle();

    final viewportTop = tester.getTopLeft(find.byType(CustomScrollView)).dy;
    expect(tester.getTopLeft(find.byKey(const ValueKey('prompt'))).dy, closeTo(viewportTop, 1));
    expect(tester.getTopLeft(find.text('Today', skipOffstage: false)).dy, lessThan(viewportTop));
  });

  for (final promptHeight in [60.0, 180.0, 720.0]) {
    testWidgets('prompt of height $promptHeight stays below the App Bar during streaming', (tester) async {
      final controller = ScrollController();
      final anchorKey = GlobalKey();
      addTearDown(controller.dispose);

      await tester.pumpWidget(chat(controller: controller, anchorKey: anchorKey, promptHeight: promptHeight, responseHeight: 48, composerHeight: 240));
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      final scroll = Scrollable.ensureVisible(anchorKey.currentContext!, alignment: 0, duration: const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      await scroll;

      final viewport = find.byType(CustomScrollView);
      final prompt = find.byKey(const ValueKey('prompt'));
      final response = find.byKey(const ValueKey('response'));
      final anchoredOffset = controller.offset;
      expect(tester.getTopLeft(prompt).dy, closeTo(tester.getTopLeft(viewport).dy, 1));

      // Closing the keyboard and growing from a short to a long reply must
      // preserve the prompt's position without another scroll command.
      for (final height in [48.0, 240.0, 1300.0]) {
        await tester.pumpWidget(chat(controller: controller, anchorKey: anchorKey, promptHeight: promptHeight, responseHeight: height));
        await tester.pumpAndSettle();
        expect(controller.offset, closeTo(anchoredOffset, 1));
        expect(tester.getTopLeft(prompt).dy, closeTo(tester.getTopLeft(viewport).dy, 1));
        expect(tester.getTopLeft(response).dy, closeTo(tester.getBottomLeft(prompt).dy, 1));
      }

      await tester.drag(viewport, const Offset(0, -160));
      await tester.pumpAndSettle();
      final manualOffset = controller.offset;
      expect(manualOffset, greaterThan(anchoredOffset));
      await tester.pumpWidget(chat(controller: controller, anchorKey: anchorKey, promptHeight: promptHeight, responseHeight: 1600));
      await tester.pumpAndSettle();
      expect(controller.offset, closeTo(manualOffset, 1));
    });
  }

  testWidgets('a new short turn reserves only its remaining viewport space', (tester) async {
    final controller = ScrollController();
    final anchorKey = GlobalKey();
    addTearDown(controller.dispose);
    await tester.pumpWidget(chat(controller: controller, anchorKey: anchorKey, promptHeight: 60, responseHeight: 48));
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(anchorKey.currentContext!, alignment: 0);
    final firstOffset = controller.offset;

    await tester.pumpWidget(chat(controller: controller, anchorKey: anchorKey, promptHeight: 180, responseHeight: 48, priorTurnHeight: 108));
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(anchorKey.currentContext!, alignment: 0);
    await tester.pumpAndSettle();

    expect(controller.offset - firstOffset, closeTo(108, 1));
    expect(tester.getTopLeft(find.byKey(const ValueKey('prompt'))).dy, closeTo(tester.getTopLeft(find.byType(CustomScrollView)).dy, 1));
    expect(controller.position.maxScrollExtent - controller.offset, closeTo(16, 1));
  });
}

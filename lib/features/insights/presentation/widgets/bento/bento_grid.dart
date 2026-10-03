part of 'bento_widgets.dart';

/// Bento grid layout presentation components.

class BentoGrid extends StatelessWidget {
  const BentoGrid({super.key, required this.children, this.gap = BentoMetrics.gridGap, this.runSpacing});

  final List<BentoTile> children;
  final double gap;
  final double? runSpacing;

  /// Splits the flat tile list into visual rows the way CSS grid auto-flow
  /// does: a span-2 tile takes a row to itself, 1x1 tiles pair up, and a lone
  /// trailing 1x1 keeps its half-width slot so the column rhythm holds.
  @visibleForTesting
  static List<List<BentoTile>> computeRows(List<BentoTile> tiles) {
    final rows = <List<BentoTile>>[];
    var i = 0;
    while (i < tiles.length) {
      if (tiles[i].spanTwo) {
        rows.add([tiles[i]]);
        i += 1;
      } else if (i + 1 < tiles.length && !tiles[i + 1].spanTwo) {
        rows.add([tiles[i], tiles[i + 1]]);
        i += 2;
      } else {
        rows.add([tiles[i]]);
        i += 1;
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final g = gap.w;
      final rg = (runSpacing ?? gap).w;
      final half = (constraints.maxWidth - g) / 2;
      final rows = computeRows(children);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var r = 0; r < rows.length; r++) ...[if (r > 0) SizedBox(height: rg), _BentoRow(tiles: rows[r], halfWidth: half, gap: g, fullWidth: constraints.maxWidth)],
        ],
      );
    },
  );
}

/// One grid row. [IntrinsicHeight] + `CrossAxisAlignment.stretch` is what makes
/// row-mates equal height, reproducing CSS grid's default `align-items:
/// stretch`. Without it a `Wrap` sizes every tile to its own content, which is
/// how a 64px height gap between two cards in the same row crept in.
class _BentoRow extends StatelessWidget {
  const _BentoRow({required this.tiles, required this.halfWidth, required this.gap, required this.fullWidth});

  final List<BentoTile> tiles;
  final double halfWidth;
  final double gap;
  final double fullWidth;

  @override
  Widget build(BuildContext context) {
    if (tiles.length == 1 && tiles.first.spanTwo) {
      return IntrinsicHeight(
        child: SizedBox(width: fullWidth, child: tiles.first.child),
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: halfWidth, child: tiles.first.child),
          SizedBox(width: gap),
          // A lone 1x1 keeps an empty second slot so the next row still lines up.
          SizedBox(width: halfWidth, child: tiles.length > 1 ? tiles[1].child : null),
        ],
      ),
    );
  }
}

/// A [BentoCard] paired with the flag that says whether it spans both columns.
class BentoTile {
  const BentoTile(this.child, {this.spanTwo = false});
  final Widget child;
  final bool spanTwo;
}

/// The score hero (`.score-hero-standout`).
///
/// Reused by screens 01, 02, 03 and 07 with different eyebrow/badge copy, so
/// every knob the mock varies is a parameter rather than a separate widget.

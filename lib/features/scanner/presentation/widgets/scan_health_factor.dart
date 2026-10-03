part of 'scan_summary_sheet.dart';

/// Scan health-factor value object.

class _HealthFactor {
  _HealthFactor({
    required this.label,
    required this.value,
    required this.description,
    required this.color,
    required this.icon,
    this.details = const [],
    this.isPositive = true,
    this.points = 0,
    this.useTick = false,
    this.expandable = true,
    this.detailsArePlain = false,
  });
  final String label;
  final String value;
  final String description;
  final Color color;
  final IconData icon;
  final List<String> details;
  final bool isPositive;
  final int points;
  final bool useTick;
  final bool expandable;

  /// True when [details] are informational lines (allergens, traces) that
  /// must render verbatim — false when they are additive labels to resolve
  /// against the concern database.
  final bool detailsArePlain;

  String get longDescription {
    if (details.isNotEmpty) return '';
    final impact = isPositive ? 'positive' : 'negative';
    final action = isPositive ? 'supports' : 'can disrupt';
    final absPoints = points.abs();
    final pointNote = absPoints > 2 ? ' (Impact: -$absPoints points)' : '';

    // Narrative logic based on label
    switch (label.toLowerCase()) {
      case 'calories':
        return isPositive
            ? 'A low energy density supports metabolic efficiency and helps maintain a healthy weight without overloading the system.'
            : 'Higher calorie density can lead to unwanted weight gain and metabolic stress if not balanced with physical activity.$pointNote';
      case 'saturated fat':
        return isPositive
            ? 'Absence of saturated fats helps maintain low levels of systemic inflammation and supports vascular health.'
            : 'High intake of saturated fats is linked to increased systemic inflammation and can negatively alter gut microbiota diversity.$pointNote';
      case 'sugar':
        return isPositive
            ? 'Zero or low sugar content prevents rapid glucose spikes, supporting stable energy levels and protecting the gut barrier.'
            : 'High sugar intake can trigger rapid insulin spikes and feed non-beneficial gut bacteria, potentially leading to dysbiosis.$pointNote';
      case 'sodium':
        return 'Significant sodium intake can affect blood pressure and may influence the gut-immune axis, potentially increasing inflammatory signals.$pointNote';
      case 'fiber':
        return 'High fiber content is essential for gut motility and acts as a prebiotic, feeding the beneficial bacteria that produce short-chain fatty acids.';
      case 'protein':
        return 'A good source of protein provides the essential amino acids needed for tissue repair and the maintenance of the intestinal lining.';
      case 'processing':
        return isPositive
            ? 'Minimally processed foods retain their natural structure and micronutrients, which are more easily recognized and utilized by your gut.'
            : 'Ultra-processing often strips natural fiber and adds industrial markers that can interfere with normal satiety signals and gut health.';
      case 'organic':
        return 'Certified organic products are produced without synthetic pesticides, reducing the chemical load on your microbiome.';
      case 'palm oil':
        return 'Palm oil is high in saturated fat and its production is a major driver of deforestation. Choosing palm-oil-free products is kinder to your gut and the planet.';
      case 'environment':
        return isPositive
            ? 'This product has one of the best environmental footprints in its category, according to the Open Food Facts Eco-Score.'
            : 'This product has a below-average environmental footprint (Eco-Score), driven by its ingredients, packaging or transport.';
      default:
        return 'This property has a $impact impact on your gut health score. Maintaining optimal levels $action your long-term wellness goals.';
    }
  }
}


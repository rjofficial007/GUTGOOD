import 'package:equatable/equatable.dart';
import 'package:gutgood/core/utils/model_utils.dart';

/// How much a detected issue should change what the user does.
///
/// Competing scanners treat every flagged item as equally alarming; that is the
/// single most common criticism of the category. Severity lets GutGood say
/// "worth knowing" without saying "dangerous".
enum ConcernSeverity {
  /// Not worth changing behaviour over at this portion size.
  minor(label: 'Minor', rank: 1),

  /// Worth knowing, especially if eaten often.
  moderate(label: 'Moderate', rank: 2),

  /// Would matter to most people at this portion.
  important(label: 'Important', rank: 3),

  /// Highest signal in our model. Not a danger claim — see label guidance.
  higher(label: 'Higher concern', rank: 4);

  const ConcernSeverity({required this.label, required this.rank});

  final String label;
  final int rank;

  static ConcernSeverity fromString(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'minor':
        return ConcernSeverity.minor;
      case 'moderate':
        return ConcernSeverity.moderate;
      case 'important':
        return ConcernSeverity.important;
      case 'higher':
        return ConcernSeverity.higher;
      default:
        return ConcernSeverity.moderate;
    }
  }
}

/// A genuinely positive property of the food, grounded in detected data.
class InsightPositive extends Equatable {
  const InsightPositive({required this.title, this.detail = ''});

  final String title;
  final String detail;

  factory InsightPositive.fromMap(Map<String, dynamic> map) => InsightPositive(
    title: ModelUtils.parseString(map['title']) ?? '',
    detail: ModelUtils.parseString(map['detail']) ?? '',
  );

  Map<String, dynamic> toMap() => {'title': title, 'detail': detail};

  @override
  List<Object?> get props => [title, detail];
}


/// A concern with an explicit severity, so the UI can rank rather than list.
class InsightConcern extends Equatable {
  const InsightConcern({required this.title, this.detail = '', this.severity = ConcernSeverity.moderate});

  final String title;
  final String detail;
  final ConcernSeverity severity;

  factory InsightConcern.fromMap(Map<String, dynamic> map) => InsightConcern(
    title: ModelUtils.parseString(map['title']) ?? '',
    detail: ModelUtils.parseString(map['detail']) ?? '',
    severity: ConcernSeverity.fromString(map['severity']?.toString()),
  );

  Map<String, dynamic> toMap() => {'title': title, 'detail': detail, 'severity': severity.name};

  @override
  List<Object?> get props => [title, detail, severity];
}


/// A nutrient-level observation plus why it matters — not a restatement of the panel.
class NutritionInsight extends Equatable {
  const NutritionInsight({required this.nutrient, this.observation = '', this.whyItMatters = ''});

  final String nutrient;
  final String observation;
  final String whyItMatters;

  factory NutritionInsight.fromMap(Map<String, dynamic> map) => NutritionInsight(
    nutrient: ModelUtils.parseString(map['nutrient']) ?? '',
    observation: ModelUtils.parseString(map['observation']) ?? '',
    whyItMatters: ModelUtils.parseString(map['whyItMatters']) ?? '',
  );

  Map<String, dynamic> toMap() => {'nutrient': nutrient, 'observation': observation, 'whyItMatters': whyItMatters};

  @override
  List<Object?> get props => [nutrient, observation, whyItMatters];
}


/// A personalised reading, carrying the evidence it is based on.
///
/// `basedOn` is not decoration: it is what stops the model (and reviewers) from
/// presenting invented history as personalisation.
class PersonalizedInsight extends Equatable {
  const PersonalizedInsight({required this.observation, this.basedOn = ''});

  final String observation;
  final String basedOn;

  factory PersonalizedInsight.fromMap(Map<String, dynamic> map) => PersonalizedInsight(
    observation: ModelUtils.parseString(map['observation']) ?? '',
    basedOn: ModelUtils.parseString(map['basedOn']) ?? '',
  );

  Map<String, dynamic> toMap() => {'observation': observation, 'basedOn': basedOn};

  @override
  List<Object?> get props => [observation, basedOn];
}


/// The layered insight attached to a scan: what's good, what to watch, why it
/// matters, what it means for this user, and what to do instead.
///
/// `scoreExplanation` and `scoreFactors` are ENGINE-AUTHORED: they are filled by
/// [YukaScore.evaluate]
/// after the model responds, never by the model itself (§7: Data → Scoring
/// Engine → Score → AI Explanation, not Data → LLM → arbitrary score).
class ScanInsight extends Equatable {
  const ScanInsight({
    this.summary = '',
    this.scoreExplanation = '',
    this.scoreFactors = const [],
    this.positives = const [],
    this.concerns = const [],
    this.nutritionInsights = const [],
    this.personalizedInsights = const [],
    this.warnings = const [],
  });

  final String summary;

  /// Plain-language "why this score", composed from [scoreFactors].
  final String scoreExplanation;

  /// The engine's signed contributions (label + delta + phrase).
  final List<ScoreFactor> scoreFactors;

  final List<InsightPositive> positives;

  /// Ordered most-significant first by the model; re-sorted by severity here.
  final List<InsightConcern> concerns;

  final List<NutritionInsight> nutritionInsights;
  final List<PersonalizedInsight> personalizedInsights;

  /// Allergy / medical / safety cautions only.
  final List<String> warnings;

  bool get isEmpty =>
      summary.isEmpty &&
      scoreExplanation.isEmpty &&
      scoreFactors.isEmpty &&
      positives.isEmpty &&
      concerns.isEmpty &&
      nutritionInsights.isEmpty &&
      personalizedInsights.isEmpty &&
      warnings.isEmpty;

  /// Concerns sorted strongest-first, capped at three so the UI leads with the
  /// few things that would actually change a decision.
  List<InsightConcern> get rankedConcerns {
    final sorted = [...concerns]..sort((a, b) => b.severity.rank.compareTo(a.severity.rank));
    return sorted.take(3).toList();
  }

  List<InsightPositive> get rankedPositives => positives.take(3).toList();

  /// True when the stored factors account for [score] exactly.
  ///
  /// The current engine emits *contributions* that sum to the score. Scans
  /// saved before it existed use a 50-baseline convention (score = 50 + Σdelta),
  /// so their breakdown rows silently fail to add up. Checking the invariant
  /// lets the UI recompute instead of showing numbers that don't reconcile.
  bool factorsSumTo(int score) =>
      scoreFactors.isNotEmpty && scoreFactors.fold(0, (sum, f) => sum + f.delta) == score;

  factory ScanInsight.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ScanInsight();
    return ScanInsight(
      summary: ModelUtils.parseString(map['summary']) ?? '',
      scoreExplanation: ModelUtils.parseString(map['scoreExplanation']) ?? '',
      scoreFactors:
          (map['scoreFactors'] is List)
              ? (map['scoreFactors'] as List)
                    .whereType<Map>()
                    .map(
                      (f) => ScoreFactor(
                        label: ModelUtils.parseString(f['label']) ?? '',
                        delta: (f['delta'] as num?)?.toInt() ?? 0,
                        phrase: ModelUtils.parseString(f['phrase']) ?? '',
                      ),
                    )
                    .where((f) => f.label.isNotEmpty)
                    .toList()
              : const [],
      positives:
          (map['positives'] is List)
              ? (map['positives'] as List).whereType<Map>().map((e) => InsightPositive.fromMap(Map<String, dynamic>.from(e))).where((e) => e.title.isNotEmpty).toList()
              : const [],
      concerns:
          (map['concerns'] is List)
              ? (map['concerns'] as List).whereType<Map>().map((e) => InsightConcern.fromMap(Map<String, dynamic>.from(e))).where((e) => e.title.isNotEmpty).toList()
              : const [],
      nutritionInsights:
          (map['nutritionInsights'] is List)
              ? (map['nutritionInsights'] as List)
                    .whereType<Map>()
                    .map((e) => NutritionInsight.fromMap(Map<String, dynamic>.from(e)))
                    .where((e) => e.nutrient.isNotEmpty)
                    .toList()
              : const [],
      personalizedInsights:
          (map['personalizedInsights'] is List)
              ? (map['personalizedInsights'] as List)
                    .whereType<Map>()
                    .map((e) => PersonalizedInsight.fromMap(Map<String, dynamic>.from(e)))
                    .where((e) => e.observation.isNotEmpty)
                    .toList()
              : const [],
      warnings: (map['warnings'] is List) ? ModelUtils.parseList<String>(map['warnings']).where((w) => w.trim().isNotEmpty).toList() : const [],
    );
  }

  Map<String, dynamic> toMap() => {
    'summary': summary,
    'scoreExplanation': scoreExplanation,
    'scoreFactors': scoreFactors.map((f) => {'label': f.label, 'delta': f.delta, 'phrase': f.phrase}).toList(),
    'positives': positives.map((e) => e.toMap()).toList(),
    'concerns': concerns.map((e) => e.toMap()).toList(),
    'nutritionInsights': nutritionInsights.map((e) => e.toMap()).toList(),
    'personalizedInsights': personalizedInsights.map((e) => e.toMap()).toList(),
    'warnings': warnings,
  };

  ScanInsight copyWith({
    String? summary,
    String? scoreExplanation,
    List<ScoreFactor>? scoreFactors,
    List<InsightPositive>? positives,
    List<InsightConcern>? concerns,
    List<NutritionInsight>? nutritionInsights,
    List<PersonalizedInsight>? personalizedInsights,
    List<String>? warnings,
  }) => ScanInsight(
    summary: summary ?? this.summary,
    scoreExplanation: scoreExplanation ?? this.scoreExplanation,
    scoreFactors: scoreFactors ?? this.scoreFactors,
    positives: positives ?? this.positives,
    concerns: concerns ?? this.concerns,
    nutritionInsights: nutritionInsights ?? this.nutritionInsights,
    personalizedInsights: personalizedInsights ?? this.personalizedInsights,
    warnings: warnings ?? this.warnings,
  );

  @override
  List<Object?> get props => [
    summary,
    scoreExplanation,
    scoreFactors,
    positives,
    concerns,
    nutritionInsights,
    personalizedInsights,
    warnings,
  ];
}

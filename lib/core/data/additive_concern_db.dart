/// Curated gut-centric additive reference.
///
/// Maps E-numbers and common additive names to a plain-language explanation
/// plus a concern level ([AdditiveConcernLevel]). Used by:
/// - the deterministic gut score (penalty by concern, never by count), and
/// - the Scan Results additives section + additive detail screens.
///
/// Levels are intentionally gut-focused (gut barrier, microbiome, inflammation,
/// sensitivities) rather than general toxicology. Unknown items resolve to
/// [AdditiveConcernLevel.unknown], which carries the same minimal penalty as
/// low so obscure-but-safe codes are never over-penalized.
library;

part 'additive_concern_flavor_enhancers.dart';
part 'additive_concern_colors.dart';
part 'additive_concern_sweeteners.dart';
part 'additive_concern_emulsifiers.dart';
part 'additive_concern_acids.dart';
part 'additive_concern_preservatives.dart';
part 'additive_concern_gums_and_colors.dart';
part 'additive_concern_name_only.dart';

enum AdditiveConcernLevel {
  /// Widely used, no meaningful gut signal at typical doses.
  low(label: 'Low'),

  /// Worth knowing about: sensitivity, microbiome or dose-dependent signal.
  moderate(label: 'Moderate'),

  /// Strongest signal: barrier, microbiome or long-term concern. Minimize.
  higher(label: 'Higher'),

  /// Not in our database yet. Shown as "Limited data", penalized like low.
  unknown(label: 'Limited data');

  const AdditiveConcernLevel({required this.label});

  final String label;
}

class AdditiveConcern {
  const AdditiveConcern({required this.code, required this.name, required this.whatItIs, required this.whyUsed, required this.level, required this.whyFlagged, required this.explanation, this.category = '', this.carefulFor = '', this.tip = ''});

  factory AdditiveConcern.fromMap(Map<String, dynamic> map) => AdditiveConcern(
    code: map['code']?.toString() ?? '',
    name: map['name']?.toString() ?? '',
    whatItIs: map['whatItIs']?.toString() ?? '',
    whyUsed: map['whyUsed']?.toString() ?? '',
    level: AdditiveConcernLevel.values.firstWhere((l) => l.name == map['level']?.toString(), orElse: () => AdditiveConcernLevel.unknown),
    whyFlagged: map['whyFlagged']?.toString() ?? '',
    explanation: map['explanation']?.toString() ?? '',
    category: map['category']?.toString() ?? '',
    carefulFor: map['carefulFor']?.toString() ?? '',
    tip: map['tip']?.toString() ?? '',
  );

  /// Fallback for items not in the database. Tracked without a score penalty.
  factory AdditiveConcern.unknown(String rawLabel) {
    final label = rawLabel.trim().isEmpty ? 'Unknown additive' : rawLabel.trim();
    return AdditiveConcern(
      code: _looksLikeCode(label) ? label.toUpperCase() : '',
      name: _looksLikeCode(label) ? 'Food additive $label'.toUpperCase() : label,
      whatItIs: 'A food additive with limited independent data in our database.',
      whyUsed: 'Used for processing, texture, color, flavor or shelf life.',
      level: AdditiveConcernLevel.unknown,
      whyFlagged: 'Limited data',
      explanation: 'We don\'t have enough information to assess $label, so it is recorded without reducing the product score.',
    );
  }

  /// Display code, e.g. 'E621'. Empty for name-only entries like 'Palm Oil'.
  final String code;

  /// Common name, e.g. 'Monosodium Glutamate'.
  final String name;

  /// One line: what the substance is.
  final String whatItIs;

  /// One line: why manufacturers add it.
  final String whyUsed;

  final AdditiveConcernLevel level;

  /// One line: the specific reason it is flagged (shown on detail screen).
  final String whyFlagged;

  /// 2-3 plain-language sentences for the detail screen.
  final String explanation;

  /// Functional category shown on list/detail screens, e.g. 'Preservative'.
  final String category;

  /// Who should be careful with this additive (detail screen). Empty means
  /// the UI falls back to level-based guidance.
  final String carefulFor;

  /// Practical tip for avoiding or handling it. Empty → level fallback.
  final String tip;

  /// Pill label for list rows: 'High concern' / 'Limited concern' /
  /// 'Low concern' / 'Limited data'.
  String get concernLabel => switch (level) {
    AdditiveConcernLevel.higher => 'High concern',
    AdditiveConcernLevel.moderate => 'Limited concern',
    AdditiveConcernLevel.low => 'Low concern',
    AdditiveConcernLevel.unknown => 'Limited data',
  };

  /// Pill label for the detail header: 'High-risk' / 'Moderate risk' /
  /// 'Low risk' / 'Limited data'.
  String get riskLabel => switch (level) {
    AdditiveConcernLevel.higher => 'High-risk',
    AdditiveConcernLevel.moderate => 'Moderate risk',
    AdditiveConcernLevel.low => 'Low risk',
    AdditiveConcernLevel.unknown => 'Limited data',
  };

  /// Points this additive costs on the displayed score, rounded from the
  /// engine's 30%-weighted contribution. Unknown concerns have no deduction.
  int get scoreImpactPts => switch (level) {
    AdditiveConcernLevel.higher => 7,
    AdditiveConcernLevel.moderate => 3,
    AdditiveConcernLevel.low => 1,
    AdditiveConcernLevel.unknown => 0,
  };

  /// Title shown in rows: 'E621 · Monosodium Glutamate' or just the name.
  String get displayTitle => code.isEmpty ? name : '$code · $name';

  Map<String, dynamic> toMap() => {
    'code': code,
    'name': name,
    'whatItIs': whatItIs,
    'whyUsed': whyUsed,
    'level': level.name,
    'whyFlagged': whyFlagged,
    'explanation': explanation,
    'category': category,
    'carefulFor': carefulFor,
    'tip': tip,
  };

  static bool _looksLikeCode(String label) => RegExp(r'^e\s?\d{3,4}[a-z]?$', caseSensitive: false).hasMatch(label.trim());
}

class AdditiveConcernDb {
  AdditiveConcernDb._();

  static final Map<String, AdditiveConcern> _byKey = {
    // --- Flavor enhancers ---
    'E621': _msg,
    'MSG': _msg,
    '621': _msg,
    'MONOSODIUM GLUTAMATE': _msg,
    'E631': _e631,
    '631': _e631,
    'DISODIUM INOSINATE': _e631,
    'E627': _e627,
    '627': _e627,
    'DISODIUM GUANYLATE': _e627,
    // --- Colors ---
    'E150D': _caramel4,
    '150D': _caramel4,
    'CARAMEL IV': _caramel4,
    'CARAMEL COLOUR IV': _caramel4,
    'SULPHITE AMMONIA CARAMEL': _caramel4,
    'E102': _tartrazine,
    '102': _tartrazine,
    'TARTRAZINE': _tartrazine,
    'E110': _sunsetYellow,
    '110': _sunsetYellow,
    'SUNSET YELLOW': _sunsetYellow,
    'E122': _azorubine,
    '122': _azorubine,
    'AZORUBINE': _azorubine,
    'CARMOISINE': _azorubine,
    'E124': _ponceau,
    '124': _ponceau,
    'PONCEAU 4R': _ponceau,
    'E129': _allura,
    '129': _allura,
    'ALLURA RED': _allura,
    'E133': _brilliantBlue,
    '133': _brilliantBlue,
    'BRILLIANT BLUE': _brilliantBlue,
    'E171': _titanium,
    '171': _titanium,
    'TITANIUM DIOXIDE': _titanium,
    'E160B': _annatto,
    '160B': _annatto,
    'ANNATTO': _annatto,
    'E160A': _carotenes,
    '160A': _carotenes,
    'CAROTENES': _carotenes,
    'BETA CAROTENE': _carotenes,
    'E160C': _paprika,
    '160C': _paprika,
    'PAPRIKA EXTRACT': _paprika,
    'PAPRIKA OLEORESIN': _paprika,
    'E100': _curcumin,
    '100': _curcumin,
    'CURCUMIN': _curcumin,
    'E140': _chlorophyll,
    '140': _chlorophyll,
    'E141': _chlorophyll,
    '141': _chlorophyll,
    'CHLOROPHYLL': _chlorophyll,
    // --- Sweeteners ---
    'E951': _aspartame,
    '951': _aspartame,
    'ASPARTAME': _aspartame,
    'E950': _acesulfame,
    '950': _acesulfame,
    'ACESULFAME': _acesulfame,
    'ACESULFAME POTASSIUM': _acesulfame,
    'ACE-K': _acesulfame,
    'E955': _sucralose,
    '955': _sucralose,
    'SUCRALOSE': _sucralose,
    'E954': _saccharin,
    '954': _saccharin,
    'SACCHARIN': _saccharin,
    'E960': _stevia,
    '960': _stevia,
    'STEVIA': _stevia,
    'STEVIOL': _stevia,
    // --- Emulsifiers / thickeners ---
    'E407': _carrageenan,
    '407': _carrageenan,
    'CARRAGEENAN': _carrageenan,
    'E466': _cmc,
    '466': _cmc,
    'CARBOXYMETHYL CELLULOSE': _cmc,
    'CMC': _cmc,
    'E461': _methylcellulose,
    '461': _methylcellulose,
    'METHYL CELLULOSE': _methylcellulose,
    'E433': _polysorbate,
    '433': _polysorbate,
    'POLYSORBATE 80': _polysorbate,
    'POLYSORBATE': _polysorbate,
    'E471': _e471,
    '471': _e471,
    'MONO- AND DIGLYCERIDES': _e471,
    'MONO AND DIGLYCERIDES': _e471,
    'E472E': _e472e,
    '472E': _e472e,
    'DATEM': _e472e,
    'E476': _e476,
    '476': _e476,
    'PGPR': _e476,
    'E322': _lecithin,
    '322': _lecithin,
    'LECITHIN': _lecithin,
    'SOY LECITHIN': _lecithin,
    'SUNFLOWER LECITHIN': _lecithin,
    'E415': _xanthan,
    '415': _xanthan,
    'XANTHAN GUM': _xanthan,
    'XANTHAN': _xanthan,
    'E412': _guar,
    '412': _guar,
    'GUAR GUM': _guar,
    'E410': _locust,
    '410': _locust,
    'LOCUST BEAN GUM': _locust,
    'CAROB GUM': _locust,
    'E440': _pectin,
    '440': _pectin,
    'PECTIN': _pectin,
    // --- Acids ---
    'E330': _citricAcid,
    '330': _citricAcid,
    'CITRIC ACID': _citricAcid,
    'E331': _sodiumCitrate,
    '331': _sodiumCitrate,
    'SODIUM CITRATE': _sodiumCitrate,
    'E296': _malicAcid,
    '296': _malicAcid,
    'MALIC ACID': _malicAcid,
    'E270': _lacticAcid,
    '270': _lacticAcid,
    'LACTIC ACID': _lacticAcid,
    'E338': _phosphoricAcid,
    '338': _phosphoricAcid,
    'PHOSPHORIC ACID': _phosphoricAcid,
    // --- Phosphates (family) ---
    'E339': _phosphates,
    '339': _phosphates,
    'E340': _phosphates,
    '340': _phosphates,
    'E341': _phosphates,
    '341': _phosphates,
    'E450': _phosphates,
    '450': _phosphates,
    'DIPHOSPHATES': _phosphates,
    'E451': _phosphates,
    '451': _phosphates,
    'E452': _phosphates,
    '452': _phosphates,
    'POLYPHOSPHATES': _phosphates,
    'SODIUM PHOSPHATE': _phosphates,
    // --- Preservatives / antioxidants ---
    'E202': _sorbate,
    '202': _sorbate,
    'POTASSIUM SORBATE': _sorbate,
    'SORBATE': _sorbate,
    'E211': _benzoate,
    '211': _benzoate,
    'SODIUM BENZOATE': _benzoate,
    'BENZOATE': _benzoate,
    'E220': _sulphites,
    '220': _sulphites,
    'E221': _sulphites,
    '221': _sulphites,
    'E222': _sulphites,
    '222': _sulphites,
    'E223': _sulphites,
    '223': _sulphites,
    'E224': _sulphites,
    '224': _sulphites,
    'E226': _sulphites,
    '226': _sulphites,
    'E227': _sulphites,
    '227': _sulphites,
    'E228': _sulphites,
    '228': _sulphites,
    'SULPHITE': _sulphites,
    'SULPHITES': _sulphites,
    'SULFITE': _sulphites,
    'SULFITES': _sulphites,
    'E250': _nitrite,
    '250': _nitrite,
    'SODIUM NITRITE': _nitrite,
    'NITRITE': _nitrite,
    'E251': _nitrate,
    '251': _nitrate,
    'SODIUM NITRATE': _nitrate,
    'E282': _propionate,
    '282': _propionate,
    'CALCIUM PROPIONATE': _propionate,
    'PROPIONATE': _propionate,
    'E319': _tbhq,
    '319': _tbhq,
    'TBHQ': _tbhq,
    'E320': _bha,
    '320': _bha,
    'BHA': _bha,
    'E321': _bht,
    '321': _bht,
    'BHT': _bht,
    'E300': _ascorbic,
    '300': _ascorbic,
    'ASCORBIC ACID': _ascorbic,
    'E306': _tocopherols,
    '306': _tocopherols,
    'E307': _tocopherols,
    '307': _tocopherols,
    'E308': _tocopherols,
    '308': _tocopherols,
    'E309': _tocopherols,
    '309': _tocopherols,
    'TOCOPHEROL': _tocopherols,
    'TOCOPHEROLS': _tocopherols,
    'VITAMIN E': _tocopherols,
    'E500': _bakingSoda,
    '500': _bakingSoda,
    'BAKING SODA': _bakingSoda,
    'SODIUM BICARBONATE': _bakingSoda,
    // --- Name-only entries ---
    'PALM OIL': _palmOil,
    'PALM FAT': _palmOil,
    'GLUCOSE SYRUP': _glucoseSyrup,
    'CORN SYRUP': _glucoseSyrup,
    'HIGH FRUCTOSE CORN SYRUP': _glucoseSyrup,
    'HFCS': _glucoseSyrup,
    'INVERT SUGAR': _invertSugar,
    'INVERT SYRUP': _invertSugar,
    'MALTODEXTRIN': _maltodextrin,
    'MODIFIED STARCH': _modifiedStarch,
    'MODIFIED FOOD STARCH': _modifiedStarch,
    'YEAST EXTRACT': _yeastExtract,
    'HYDROLYZED VEGETABLE PROTEIN': _hvp,
    'HYDROLYSED VEGETABLE PROTEIN': _hvp,
    'HVP': _hvp,
    'NATURAL FLAVOURING': _naturalFlavour,
    'NATURAL FLAVORING': _naturalFlavour,
    'NATURAL FLAVOUR': _naturalFlavour,
    'NATURAL FLAVOR': _naturalFlavour,
    'ARTIFICIAL FLAVOURING': _naturalFlavour,
    'ARTIFICIAL FLAVORING': _naturalFlavour,
  };

  /// Matches E-codes / INS numbers in free text: E631, E 631, E160c, INS 621.
  static final RegExp _codePattern = RegExp(r'\b(?:e|ins)\s?(\d{3,4})([a-z]?)\b', caseSensitive: false);

  /// Normalize a raw code token to DB key form: 'e 160c' → 'E160C'.
  static String normalizeCode(String raw) => raw.replaceAll(RegExp(r'\s+'), '').toUpperCase();

  /// Resolve one item (E-code, INS number or name) to its concern profile.
  /// Never returns null — unknown items get a gentle [AdditiveConcern.unknown].
  static AdditiveConcern resolve(String item) {
    final cleaned = item.trim();
    if (cleaned.isEmpty) return AdditiveConcern.unknown(cleaned);
    // Try code-style match first ('E631', 'INS 621', '621').
    final codeMatch = _codePattern.firstMatch(cleaned);
    if (codeMatch != null && codeMatch.group(0)!.length >= cleaned.length - 1) {
      final key = normalizeCode(codeMatch.group(0)!.replaceAll(RegExp('ins', caseSensitive: false), 'E'));
      final hit = _byKey[key] ?? _byKey[key.replaceFirst('E', '')];
      if (hit != null) return hit;
      return AdditiveConcern.unknown(key.startsWith('E') ? key : 'E$key');
    }
    // Bare number ('621')?
    if (RegExp(r'^\d{3,4}[a-z]?$', caseSensitive: false).hasMatch(cleaned)) {
      final key = cleaned.toUpperCase();
      return _byKey[key] ?? _byKey['E$key'] ?? AdditiveConcern.unknown('E$key');
    }
    // Name lookup (case-insensitive exact, then substring over known names).
    final upper = cleaned.toUpperCase();
    if (_byKey.containsKey(upper)) return _byKey[upper]!;
    // Longest known name contained in the text wins ('Contains palm oil' → palm oil).
    String? bestKey;
    for (final key in _byKey.keys) {
      if (key.length < 4 || RegExp(r'^[E\d]').hasMatch(key)) continue;
      if (upper.contains(key) && (bestKey == null || key.length > bestKey.length)) bestKey = key;
    }
    if (bestKey != null) return _byKey[bestKey]!;
    return AdditiveConcern.unknown(cleaned);
  }

  /// Resolve many items, de-duplicated by display title.
  static List<AdditiveConcern> resolveAll(Iterable<String> items) {
    final seen = <String>{};
    final out = <AdditiveConcern>[];
    for (final item in items) {
      final concern = resolve(item);
      final key = concern.displayTitle.toUpperCase();
      if (seen.add(key)) out.add(concern);
    }
    return out;
  }

  /// Extract additive items from a free-text summary (AI `additives` string).
  ///
  /// Finds E-codes/INS numbers plus any known additive names; returns readable
  /// labels ('E631', 'Palm Oil'). Returns [] for 'none'/'no additives' text.
  static List<String> parseItems(String? summary) {
    if (summary == null || summary.trim().isEmpty) return const [];
    final text = summary.trim();
    if (RegExp(r'^\s*(none|no\s+additives?( detected)?|n/?a)\b', caseSensitive: false).hasMatch(text)) return const [];
    final found = <String>[];
    final seen = <String>{};
    void add(String label) {
      final key = label.toUpperCase();
      if (seen.add(key)) found.add(label);
    }

    for (final m in _codePattern.allMatches(text)) {
      var key = normalizeCode(m.group(0)!);
      if (key.startsWith('INS')) key = 'E${key.substring(3)}';
      add(key);
    }
    final upper = text.toUpperCase();
    for (final key in _byKey.keys) {
      if (key.length < 4 || RegExp(r'^[E\d]').hasMatch(key)) continue;
      if (upper.contains(key)) {
        final concern = _byKey[key]!;
        add(concern.code.isNotEmpty ? concern.code : _titleCase(key));
      }
    }
    return found;
  }

  static String _titleCase(String input) => input.toLowerCase().split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

  /// Every distinct concern profile in the database (aliases collapsed).
  static List<AdditiveConcern> get allConcerns {
    final seen = <AdditiveConcern>{};
    for (final concern in _byKey.values) {
      seen.add(concern);
    }
    return seen.toList();
  }

  static int _rankLevel(AdditiveConcernLevel level) => switch (level) {
    AdditiveConcernLevel.higher => 3,
    AdditiveConcernLevel.moderate => 2,
    AdditiveConcernLevel.low => 1,
    AdditiveConcernLevel.unknown => 0,
  };

  /// Same-category additives for the "Related" section, concern-first.
  /// Empty when the category is unknown (nothing honest to relate).
  static List<AdditiveConcern> relatedTo(AdditiveConcern concern, {int limit = 4}) {
    if (concern.category.isEmpty) return const [];
    final items = allConcerns.where((c) => c.category == concern.category && c.displayTitle != concern.displayTitle).toList()
      ..sort((a, b) {
        final rank = _rankLevel(b.level).compareTo(_rankLevel(a.level));
        return rank != 0 ? rank : a.name.compareTo(b.name);
      });
    return items.take(limit).toList();
  }
}

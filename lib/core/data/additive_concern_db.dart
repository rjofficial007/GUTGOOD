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

  /// Fallback for items not in the database. Penalized like low.
  factory AdditiveConcern.unknown(String rawLabel) {
    final label = rawLabel.trim().isEmpty ? 'Unknown additive' : rawLabel.trim();
    return AdditiveConcern(
      code: _looksLikeCode(label) ? label.toUpperCase() : '',
      name: _looksLikeCode(label) ? 'Food additive $label'.toUpperCase() : label,
      whatItIs: 'A food additive with limited independent data in our database.',
      whyUsed: 'Used for processing, texture, color, flavor or shelf life.',
      level: AdditiveConcernLevel.unknown,
      whyFlagged: 'Limited data',
      explanation:
          'We don\'t have a full profile for $label yet, so we treat it gently in your score. '
          'As a rule of thumb, fewer hard-to-pronounce ingredients usually means a kinder food for your gut.',
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

  /// Points this additive costs on the displayed score: the engine's
  /// 30%-weighted contribution (25/10/2 subscore pts → 8/3/1).
  int get scoreImpactPts => switch (level) {
    AdditiveConcernLevel.higher => 8,
    AdditiveConcernLevel.moderate => 3,
    AdditiveConcernLevel.low => 1,
    AdditiveConcernLevel.unknown => 1,
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

  static const AdditiveConcern _msg = AdditiveConcern(
    code: 'E621',
    category: 'Flavor enhancer',
    carefulFor: 'MSG-sensitive people — headaches or flushing after savory snacks is the tell.',
    tip: 'Cook savory food with mushrooms, tomato or parmesan for natural umami.',
    name: 'Monosodium Glutamate (MSG)',
    whatItIs: 'The sodium salt of glutamic acid, an amino acid found naturally in tomatoes and cheese.',
    whyUsed: 'Boosts savory (umami) flavor so products taste richer with less real food.',
    level: AdditiveConcernLevel.moderate,
    whyFlagged: 'Sensitivity trigger for some people',
    explanation:
        'Most people handle MSG fine, but a sensitive minority report headaches, flushing or gut discomfort after larger amounts. '
        'It also makes ultra-processed food hyper-palatable, so you tend to eat past fullness. Fine occasionally — not an everyday staple.',
  );

  static const AdditiveConcern _e631 = AdditiveConcern(
    code: 'E631',
    category: 'Flavor enhancer',
    name: 'Disodium Inosinate',
    whatItIs: 'A flavor enhancer made from inosinic acid, often paired with MSG.',
    whyUsed: 'Multiplies MSG\'s savory effect so a pinch flavors a whole pack.',
    level: AdditiveConcernLevel.moderate,
    whyFlagged: 'Ultra-processing signal, amplifies MSG',
    explanation:
        'On its own it is considered safe, but it almost always travels with MSG in heavily flavored snacks and instant noodles. '
        'Seeing it is a reliable sign the flavor comes from a lab blend rather than real ingredients.',
  );

  static const AdditiveConcern _e627 = AdditiveConcern(
    code: 'E627',
    category: 'Flavor enhancer',
    name: 'Disodium Guanylate',
    whatItIs: 'A flavor enhancer made from guanylic acid, MSG\'s usual partner.',
    whyUsed: 'Works with MSG and E631 to create intense savory flavor cheaply.',
    level: AdditiveConcernLevel.moderate,
    whyFlagged: 'Ultra-processing signal, amplifies MSG',
    explanation:
        'Same story as E631: safe in isolation, but a marker of engineered flavor in instant noodles, chips and soup mixes. '
        'If you are sensitive to MSG, treat products listing E627 the same way.',
  );

  static const AdditiveConcern _caramel4 = AdditiveConcern(
    code: 'E150d',
    category: 'Food coloring',
    name: 'Caramel Colour IV (Sulphite Ammonia)',
    whatItIs: 'A dark brown color made by heating sugars with sulphite and ammonia compounds.',
    whyUsed: 'Gives colas, sauces and gravies their dark appetizing color.',
    level: AdditiveConcernLevel.higher,
    whyFlagged: 'Contains 4-MEI, a possible carcinogen',
    explanation:
        'The manufacturing process creates 4-MEI, which California lists as a possible carcinogen and regulators cap in drinks. '
        'It adds color only — zero nutrition. Choose products colored with real ingredients (like caramelized sugar or cocoa) instead.',
  );

  static const AdditiveConcern _tartrazine = AdditiveConcern(
    code: 'E102',
    category: 'Food coloring',
    carefulFor: 'Children, and people sensitive to aspirin or dyes.',
    name: 'Tartrazine',
    whatItIs: 'A synthetic lemon-yellow azo dye.',
    whyUsed: 'Makes sweets, drinks and noodles look bright yellow.',
    level: AdditiveConcernLevel.higher,
    whyFlagged: 'Azo dye: hyperactivity & sensitivity link',
    explanation:
        'Azo dyes like tartrazine must carry a warning in the EU that they "may have an adverse effect on activity and attention in children". '
        'They can also trigger reactions in aspirin-sensitive people. Real color from turmeric or saffron beats yellow dye every time.',
  );

  static const AdditiveConcern _sunsetYellow = AdditiveConcern(
    code: 'E110',
    category: 'Food coloring',
    carefulFor: 'Children, and people sensitive to aspirin or dyes.',
    name: 'Sunset Yellow',
    whatItIs: 'A synthetic orange-yellow azo dye.',
    whyUsed: 'Colors sweets, syrups, instant noodles and snacks orange.',
    level: AdditiveConcernLevel.higher,
    whyFlagged: 'Azo dye: hyperactivity & sensitivity link',
    explanation:
        'Same EU warning group as tartrazine: possible effects on activity and attention in children, plus sensitivity reactions in some adults. '
        'It exists purely for looks. Paprika or annatto gives the same warmth without the dye.',
  );

  static const AdditiveConcern _azorubine = AdditiveConcern(
    code: 'E122',
    category: 'Food coloring',
    carefulFor: 'Children, and people sensitive to aspirin or dyes.',
    name: 'Azorubine (Carmoisine)',
    whatItIs: 'A synthetic red azo dye.',
    whyUsed: 'Colors jellies, sweets and drinks red or pink.',
    level: AdditiveConcernLevel.higher,
    whyFlagged: 'Azo dye: hyperactivity & sensitivity link',
    explanation:
        'Another azo dye in the EU "may affect activity and attention in children" warning group. '
        'Beetroot and berries color food red naturally — this one only needs to exist for shelf-stable brightness.',
  );

  static const AdditiveConcern _ponceau = AdditiveConcern(
    code: 'E124',
    category: 'Food coloring',
    carefulFor: 'Children, and people sensitive to aspirin or dyes.',
    name: 'Ponceau 4R',
    whatItIs: 'A synthetic red azo dye.',
    whyUsed: 'Colors sweets, desserts and drinks a stable red.',
    level: AdditiveConcernLevel.higher,
    whyFlagged: 'Azo dye: hyperactivity & sensitivity link',
    explanation:
        'Banned in the US and Norway, restricted elsewhere — yet still common in some markets\' sweets and syrups. '
        'In the same hyperactivity-warning dye family. Best avoided, especially for kids.',
  );

  static const AdditiveConcern _allura = AdditiveConcern(
    code: 'E129',
    category: 'Food coloring',
    carefulFor: 'Children, and people sensitive to aspirin or dyes.',
    name: 'Allura Red',
    whatItIs: 'A synthetic red azo dye.',
    whyUsed: 'The go-to red for candy, soft drinks and cereals.',
    level: AdditiveConcernLevel.higher,
    whyFlagged: 'Azo dye: hyperactivity & sensitivity link',
    explanation:
        'One of the most-studied azo dyes, in the EU children\'s warning group, and research keeps probing its gut-microbiome effects. '
        'Red food should get its color from fruit and vegetables — not this.',
  );

  static const AdditiveConcern _brilliantBlue = AdditiveConcern(
    code: 'E133',
    category: 'Food coloring',
    name: 'Brilliant Blue',
    whatItIs: 'A synthetic blue dye (also used to make greens with yellow dyes).',
    whyUsed: 'Colors candy, frostings, drinks and ice cream blue or green.',
    level: AdditiveConcernLevel.moderate,
    whyFlagged: 'Synthetic dye with gut-permeability questions',
    explanation:
        'Blue is the rarest color in real food, so this dye is a dead giveaway of heavy processing. '
        'Early research has raised questions about synthetic dyes and gut permeability — worth minimizing while science catches up.',
  );

  static const AdditiveConcern _aspartame = AdditiveConcern(
    code: 'E951',
    category: 'Sweetener',
    carefulFor: 'Anyone with PKU must avoid it entirely; others may notice gut or glucose effects.',
    tip: 'Water, fruit or stevia-sweetened options avoid the issue entirely.',
    name: 'Aspartame',
    whatItIs: 'An artificial sweetener ~200x sweeter than sugar.',
    whyUsed: 'Sweetens diet sodas, gums and "sugar-free" products without calories.',
    level: AdditiveConcernLevel.moderate,
    whyFlagged: 'Possible carcinogen (WHO 2B); gut-microbiome signal',
    explanation:
        'WHO classifies aspartame as "possibly carcinogenic" and advises against using sweeteners for weight control. '
        'It can also nudge gut bacteria and glucose responses in some people. Dangerous for anyone with PKU. Water or fruit beats diet soda.',
  );

  static const AdditiveConcern _acesulfame = AdditiveConcern(
    code: 'E950',
    category: 'Sweetener',
    tip: 'Water, fruit or stevia-sweetened options avoid the issue entirely.',
    name: 'Acesulfame Potassium (Ace-K)',
    whatItIs: 'A calorie-free artificial sweetener, often blended with aspartame or sucralose.',
    whyUsed: 'Sweetens diet drinks, protein powders and sugar-free gum.',
    level: AdditiveConcernLevel.moderate,
    whyFlagged: 'Emerging gut-microbiome and glucose signal',
    explanation:
        'Newer human trials link common sweetener blends containing Ace-K to shifts in gut bacteria and blood-sugar responses. '
        'It is not absorbed for energy, but your microbes still notice it. An everyday habit worth rethinking.',
  );

  static const AdditiveConcern _sucralose = AdditiveConcern(
    code: 'E955',
    category: 'Sweetener',
    tip: 'Water, fruit or stevia-sweetened options avoid the issue entirely.',
    name: 'Sucralose',
    whatItIs: 'An artificial sweetener made by chlorinating sugar (~600x sweeter).',
    whyUsed: 'Sweetens diet products, protein bars and "zero sugar" snacks.',
    level: AdditiveConcernLevel.moderate,
    whyFlagged: 'Microbiome effects; breaks down when heated',
    explanation:
        'Sucralose can reduce beneficial gut bacteria in animal studies, and heating it (baking, hot drinks) may release concerning compounds. '
        'WHO advises against sweeteners for weight control generally. Fine rarely — not a daily swap for sugar.',
  );

  static const AdditiveConcern _saccharin = AdditiveConcern(
    code: 'E954',
    category: 'Sweetener',
    tip: 'Water, fruit or stevia-sweetened options avoid the issue entirely.',
    name: 'Saccharin',
    whatItIs: 'The oldest artificial sweetener (~300x sweeter than sugar).',
    whyUsed: 'Sweetens diet drinks, mouthwash-flavored products and tabletop sweeteners.',
    level: AdditiveConcernLevel.moderate,
    whyFlagged: 'Blood-sugar and microbiome effects in trials',
    explanation:
        'Human trials found saccharin can blunt glucose tolerance via gut-microbiome shifts within days in some people. '
        'It is calorie-free but not consequence-free. If you need sweet, a little real sugar or fruit is the more honest choice.',
  );

  static const AdditiveConcern _stevia = AdditiveConcern(
    code: 'E960',
    category: 'Sweetener',
    name: 'Steviol Glycosides (Stevia)',
    whatItIs: 'Sweet compounds extracted from the stevia leaf.',
    whyUsed: 'A plant-derived way to sweeten drinks and snacks without sugar.',
    level: AdditiveConcernLevel.low,
    whyFlagged: '',
    explanation:
        'The best-studied "natural" sweetener with a solid safety record at normal intakes. '
        'Highly purified extracts are not the same as the whole leaf, but for your gut this is the gentlest sweetener choice on shelf.',
  );

  static const AdditiveConcern _carrageenan = AdditiveConcern(
    code: 'E407',
    category: 'Thickener',
    carefulFor: 'People with IBS or IBD — the gut-inflammation evidence matters most here.',
    tip: 'Check plant milks and yogurts — carrageenan-free versions exist for everything.',
    name: 'Carrageenan',
    whatItIs: 'A thickener extracted from red seaweed.',
    whyUsed: 'Thickens plant milks, ice cream, yogurts and deli meats.',
    level: AdditiveConcernLevel.higher,
    whyFlagged: 'Directly linked to gut inflammation in trials',
    explanation:
        'This is the big one for gut health: human trials show even food-grade carrageenan can raise intestinal inflammation and permeability. '
        'It hides in "healthy" almond milks and yogurts. Always check the label — carrageenan-free versions exist for everything.',
  );

  static const AdditiveConcern _cmc = AdditiveConcern(
    code: 'E466',
    category: 'Thickener',
    name: 'Carboxymethyl Cellulose (CMC)',
    whatItIs: 'A chemically modified plant-fiber thickener and emulsifier.',
    whyUsed: 'Keeps ice cream smooth, sauces stable and gluten-free bread soft.',
    level: AdditiveConcernLevel.higher,
    whyFlagged: 'Human trial: erodes gut mucus barrier',
    explanation:
        'A controlled human trial found CMC thins the protective mucus layer of the gut and shifts bacteria toward an inflammatory profile. '
        'One of very few additives with direct human gut-barrier evidence. Worth actively avoiding.',
  );

  static const AdditiveConcern _methylcellulose = AdditiveConcern(
    code: 'E461',
    category: 'Thickener',
    name: 'Methyl Cellulose',
    whatItIs: 'A modified plant-fiber binder and thickener.',
    whyUsed: 'Binds plant-based burgers and thickens sauces and ice cream.',
    level: AdditiveConcernLevel.moderate,
    whyFlagged: 'Same emulsifier family as CMC (E466)',
    explanation:
        'Chemically related to CMC, which has direct human evidence of gut-barrier disruption. '
        'It has less data of its own, but the family resemblance is enough to prefer products without it.',
  );

  static const AdditiveConcern _polysorbate = AdditiveConcern(
    code: 'E433',
    category: 'Emulsifier',
    name: 'Polysorbate 80',
    whatItIs: 'A synthetic emulsifier that forces oil and water to mix.',
    whyUsed: 'Stabilizes ice cream, sauces, baked goods and supplements.',
    level: AdditiveConcernLevel.higher,
    whyFlagged: 'Human trial: disrupts gut barrier & microbiome',
    explanation:
        'Alongside CMC, polysorbate 80 is one of the few emulsifiers tested in controlled human trials — and it disturbed the gut lining and microbiome. '
        'Common in cheap ice cream and sauces. A strong reason to upgrade to simpler brands.',
  );

  static const AdditiveConcern _e471 = AdditiveConcern(
    code: 'E471',
    category: 'Emulsifier',
    name: 'Mono- and Diglycerides',
    whatItIs: 'Emulsifiers usually made from vegetable fats.',
    whyUsed: 'Keeps bread soft, ice cream creamy and spreads spreadable.',
    level: AdditiveConcernLevel.moderate,
    whyFlagged: 'Emulsifier with emerging gut signal',
    explanation:
        'Long considered harmless, but large population studies now link mono- and diglyceride intake to higher cardiovascular and metabolic risk. '
        'Your gut microbes also appear to notice emulsifiers generally. Prefer bread and spreads with short ingredient lists.',
  );

  static const AdditiveConcern _e472e = AdditiveConcern(
    code: 'E472e',
    category: 'Emulsifier',
    name: 'DATEM (Mono- and Diacetyl Tartaric Esters)',
    whatItIs: 'A synthetic dough-conditioning emulsifier.',
    whyUsed: 'Gives industrial bread big volume and a soft, springy crumb.',
    level: AdditiveConcernLevel.moderate,
    whyFlagged: 'Ultra-processing marker in industrial bread',
    explanation:
        'You will never find DATEM in a real bakery — it exists to make factory bread feel fresh for days. '
        'Not acutely harmful, but its presence means the bread is engineered, not baked. Choose bread with flour, water, salt and yeast.',
  );

  static const AdditiveConcern _e476 = AdditiveConcern(
    code: 'E476',
    category: 'Emulsifier',
    name: 'Polyglycerol Polyricinoleate (PGPR)',
    whatItIs: 'An emulsifier made from castor-bean oil.',
    whyUsed: 'Lets chocolate makers use less cocoa butter while keeping flow.',
    level: AdditiveConcernLevel.low,
    whyFlagged: '',
    explanation:
        'A cost-cutting chocolate additive with a decent safety record — it mostly signals cheaper chocolate rather than danger. '
        'If you see it, the bar probably skimps on cocoa butter. Better chocolate lists cocoa mass first and needs no PGPR.',
  );

  static const AdditiveConcern _lecithin = AdditiveConcern(
    code: 'E322',
    category: 'Emulsifier',
    name: 'Lecithins',
    whatItIs: 'Natural emulsifiers from soy, sunflower or egg yolk.',
    whyUsed: 'Blends chocolate smoothly and keeps baked goods uniform.',
    level: AdditiveConcernLevel.low,
    whyFlagged: '',
    explanation:
        'One of the gentlest emulsifiers — it is literally a component of your own cell membranes. '
        'Sunflower lecithin avoids soy concerns entirely. No reason to avoid products that use it.',
  );

  static const AdditiveConcern _citricAcid = AdditiveConcern(
    code: 'E330',
    category: 'Acidity regulator',
    name: 'Citric Acid',
    whatItIs: 'The sour acid of lemons, made industrially by fermenting sugars.',
    whyUsed: 'Adds tang and preserves soft drinks, sweets and canned food.',
    level: AdditiveConcernLevel.low,
    whyFlagged: '',
    explanation:
        'Your own cells make citric acid every second — it is about as safe as additives get. '
        'It can erode tooth enamel in fizzy drinks, but for your gut it is a non-event.',
  );

  static const AdditiveConcern _sodiumCitrate = AdditiveConcern(
    code: 'E331',
    category: 'Acidity regulator',
    name: 'Sodium Citrates',
    whatItIs: 'The sodium salts of citric acid.',
    whyUsed: 'Controls acidity and keeps processed cheese melty.',
    level: AdditiveConcernLevel.low,
    whyFlagged: '',
    explanation:
        'As benign as citric acid itself — it just sets the pH and adds a little sodium. '
        'Nothing here your body doesn\'t already handle routinely.',
  );

  static const AdditiveConcern _malicAcid = AdditiveConcern(
    code: 'E296',
    category: 'Acidity regulator',
    name: 'Malic Acid',
    whatItIs: 'The tart acid of apples.',
    whyUsed: 'Gives sour candy, drinks and gum their sharp tang.',
    level: AdditiveConcernLevel.low,
    whyFlagged: '',
    explanation:
        'A normal metabolic acid your body produces itself. '
        'In candy quantities it can bother teeth and sensitive stomachs, but it is not a gut-health concern.',
  );

  static const AdditiveConcern _lacticAcid = AdditiveConcern(
    code: 'E270',
    category: 'Acidity regulator',
    name: 'Lactic Acid',
    whatItIs: 'The mild acid of yogurt and fermented foods.',
    whyUsed: 'Adds tang and preserves bread, pickles and drinks.',
    level: AdditiveConcernLevel.low,
    whyFlagged: '',
    explanation:
        'Despite the name it is usually vegan (fermented from sugars) and identical to what your muscles and yogurt cultures make. '
        'One of the friendliest acids on a label.',
  );

  static const AdditiveConcern _phosphoricAcid = AdditiveConcern(
    code: 'E338',
    category: 'Acidity regulator',
    carefulFor: 'Daily cola drinkers — bones and kidneys feel it over time.',
    name: 'Phosphoric Acid',
    whatItIs: 'A sharp mineral acid — the bite in cola.',
    whyUsed: 'Gives colas their tang and stops bacteria and mold.',
    level: AdditiveConcernLevel.moderate,
    whyFlagged: 'Cola acid linked to bone & kidney effects',
    explanation:
        'Cola drinkers show lower bone density and higher kidney-stone risk in observational studies, and phosphoric acid is the prime suspect. '
        'An occasional cola is fine — a daily habit is where the data looks grim.',
  );

  static const AdditiveConcern _phosphates = AdditiveConcern(
    code: 'E339–E452',
    category: 'Emulsifier',
    carefulFor: 'People with kidney issues should be strictest.',
    tip: 'Whole foods beat processed ones here — phosphates hide in everything packaged.',
    name: 'Phosphate Additives',
    whatItIs: 'A family of phosphorus salts (E339, E340, E450, E451, E452...) used across processed food.',
    whyUsed: 'Retains moisture in meats, melts cheese, leavens baked goods, stabilizes drinks.',
    level: AdditiveConcernLevel.moderate,
    whyFlagged: 'Excess added phosphorus strains kidneys & heart',
    explanation:
        'Added phosphates absorb far more readily than natural phosphorus, and high intake is linked to kidney and heart strain. '
        'They hide everywhere in processed food — another reason whole foods win. People with kidney issues should be strictest.',
  );

  static const AdditiveConcern _sorbate = AdditiveConcern(
    code: 'E202',
    category: 'Preservative',
    name: 'Potassium Sorbate',
    whatItIs: 'A mold- and yeast-inhibiting preservative.',
    whyUsed: 'Keeps cheese, baked goods, wine and syrups from going moldy.',
    level: AdditiveConcernLevel.low,
    whyFlagged: '',
    explanation:
        'One of the better-tolerated preservatives with a long safety record at permitted levels. '
        'Rare skin or gut sensitivity exists but is uncommon. Fresh food needs none — packaged food mostly behaves with it.',
  );

  static const AdditiveConcern _benzoate = AdditiveConcern(
    code: 'E211',
    category: 'Preservative',
    carefulFor: 'Sensitive individuals, especially with vitamin-C-rich drinks.',
    name: 'Sodium Benzoate',
    whatItIs: 'A preservative that stops yeast, bacteria and mold in acidic foods.',
    whyUsed: 'Preserves soft drinks, pickles, sauces and jams.',
    level: AdditiveConcernLevel.moderate,
    whyFlagged: 'Can form benzene with vitamin C; sensitivity reports',
    explanation:
        'With vitamin C and heat or light, benzoate can form tiny amounts of benzene — drinks were reformulated over this, but the chemistry remains. '
        'Some people also report gut or skin sensitivity. Fine occasionally; don\'t stockpile benzoate-preserved drinks.',
  );

  static const AdditiveConcern _sulphites = AdditiveConcern(
    code: 'E220–E228',
    category: 'Preservative',
    carefulFor: 'People with asthma or sulphite sensitivity — wine and dried fruit are the classic triggers.',
    tip: 'Dried fruit without sulphites looks brown but tastes the same.',
    name: 'Sulphites',
    whatItIs: 'Sulphur-based preservatives (E220–E228) used in wine, dried fruit and juices.',
    whyUsed: 'Prevents browning and spoilage in wine, dried apricots, juices and sausages.',
    level: AdditiveConcernLevel.moderate,
    whyFlagged: 'Major trigger for asthmatics & sensitive guts',
    explanation:
        'Sulphites must be labeled because they trigger asthma attacks and gut symptoms in sensitive people — dried fruit and wine are the classic culprits. '
        'They also destroy thiamine (vitamin B1). If wine or dried fruit bothers you, sulphites are suspect number one.',
  );

  static const AdditiveConcern _nitrite = AdditiveConcern(
    code: 'E250',
    category: 'Preservative',
    carefulFor: 'Anyone eating cured meats often — risk grows with frequency.',
    tip: 'Look for uncured meats, and avoid frying bacon crisp.',
    name: 'Sodium Nitrite',
    whatItIs: 'The curing salt that keeps bacon pink and botulism away.',
    whyUsed: 'Cures ham, bacon, sausages and deli meats; fixes the pink color.',
    level: AdditiveConcernLevel.higher,
    whyFlagged: 'Forms carcinogenic nitrosamines; processed-meat risk',
    explanation:
        'Nitrite can convert into nitrosamines — potent carcinogens — especially when bacon and sausages are fried crisp. '
        'This is a big part of why WHO classifies processed meat as carcinogenic. Vitamin C in the product helps, but less cured meat is the real fix.',
  );

  static const AdditiveConcern _nitrate = AdditiveConcern(
    code: 'E251',
    category: 'Preservative',
    carefulFor: 'Anyone eating cured meats often — risk grows with frequency.',
    name: 'Sodium Nitrate',
    whatItIs: 'A curing salt that slowly converts to nitrite in meat.',
    whyUsed: 'Long-cures salami, hams and fermented sausages.',
    level: AdditiveConcernLevel.higher,
    whyFlagged: 'Converts to nitrite → nitrosamines',
    explanation:
        'Nitrate in cured meat is just nitrite with extra steps — the same nitrosamine concern applies to salami, pepperoni and cured hams. '
        '(Nitrate from spinach and beetroot is a different, beneficial story.) Treat cured meats as occasional, not everyday.',
  );

  static const AdditiveConcern _propionate = AdditiveConcern(
    code: 'E282',
    category: 'Preservative',
    carefulFor: 'People watching blood sugar — effects show up even after one meal.',
    name: 'Calcium Propionate',
    whatItIs: 'A mold inhibitor sprayed on and baked into bread.',
    whyUsed: 'Keeps packaged bread mold-free for a week or more.',
    level: AdditiveConcernLevel.moderate,
    whyFlagged: 'May disturb metabolism & gut hormones',
    explanation:
        'A human trial found propionate can raise blood sugar and insulin-disrupting hormones after a single meal. '
        'It is why supermarket bread outlives bakery bread by a week. If bread lasts forever, ask what is preserving it.',
  );

  static const AdditiveConcern _tbhq = AdditiveConcern(
    code: 'E319',
    category: 'Antioxidant',
    carefulFor: 'Frequent instant-noodle eaters — the dose makes the concern.',
    tip: 'If a noodle pack lists TBHQ, the frying oil is the problem — drain it well or switch brands.',
    name: 'TBHQ',
    whatItIs: 'A synthetic antioxidant that stops fats going rancid.',
    whyUsed: 'Preserves instant noodles, chips, frozen foods and frying oils.',
    level: AdditiveConcernLevel.higher,
    whyFlagged: 'Immune effects in studies; instant-noodle staple',
    explanation:
        'Animal and cell studies link TBHQ to immune disruption at high doses, and regulators cap it tightly for that reason. '
        'It is the signature preservative of instant noodles and cheap frying oil. If TBHQ is on the label, the fats inside are not fresh.',
  );

  static const AdditiveConcern _bha = AdditiveConcern(
    code: 'E320',
    category: 'Antioxidant',
    carefulFor: 'Children and pregnant people — endocrine signals deserve extra caution.',
    tip: 'Choose brands preserved with vitamin E (tocopherols) instead.',
    name: 'BHA (Butylated Hydroxyanisole)',
    whatItIs: 'A synthetic antioxidant for fats and oils.',
    whyUsed: 'Keeps chips, cereals, gum and instant foods from going stale.',
    level: AdditiveConcernLevel.higher,
    whyFlagged: 'Possible human carcinogen (listed in California & IARC 2B)',
    explanation:
        'BHA is listed as a possible carcinogen by IARC and California\'s Prop 65, and it can act as an endocrine disruptor. '
        'Vitamin E (tocopherols) does the same preservation job safely — brands using BHA chose the cheap route.',
  );

  static const AdditiveConcern _bht = AdditiveConcern(
    code: 'E321',
    category: 'Antioxidant',
    carefulFor: 'Children and pregnant people — endocrine signals deserve extra caution.',
    tip: 'Choose brands preserved with vitamin E (tocopherols) instead.',
    name: 'BHT (Butylated Hydroxytoluene)',
    whatItIs: 'BHA\'s chemical cousin, a synthetic fat antioxidant.',
    whyUsed: 'Preserves cereals, chips, packaging liners and chewing gum.',
    level: AdditiveConcernLevel.higher,
    whyFlagged: 'Possible carcinogen; endocrine-disruption signal',
    explanation:
        'Same family and same concerns as BHA: possible-carcinogen listings plus hormone-disruption signals in studies. '
        'It even migrates from packaging into food. Tocopherol-preserved (vitamin E) alternatives exist for nearly everything.',
  );

  static const AdditiveConcern _titanium = AdditiveConcern(
    code: 'E171',
    category: 'Food coloring',
    carefulFor: 'Children — bright white candy is the main exposure.',
    tip: 'Skip bright-white candy shells and icings — color adds nothing.',
    name: 'Titanium Dioxide',
    whatItIs: 'A mineral whitening powder (nanoparticles included).',
    whyUsed: 'Makes gum, candy shells, icing and sauces bright white.',
    level: AdditiveConcernLevel.higher,
    whyFlagged: 'Banned in the EU over genotoxicity concerns',
    explanation:
        'The EU banned E171 in food in 2022 because its nanoparticles\' DNA-damaging potential couldn\'t be ruled out. '
        'It is still allowed in some other markets. Whiteness is pure cosmetics — never worth a genotoxicity question mark.',
  );

  static const AdditiveConcern _xanthan = AdditiveConcern(
    code: 'E415',
    category: 'Thickener',
    name: 'Xanthan Gum',
    whatItIs: 'A thickener made by fermenting sugars with bacteria.',
    whyUsed: 'Thickens gluten-free baking, sauces and salad dressings.',
    level: AdditiveConcernLevel.low,
    whyFlagged: '',
    explanation:
        'Essentially a soluble fiber — well tolerated and even mildly prebiotic at food doses. '
        'Very large amounts can cause bloating, but normal servings are a non-issue for the gut.',
  );

  static const AdditiveConcern _guar = AdditiveConcern(
    code: 'E412',
    category: 'Thickener',
    name: 'Guar Gum',
    whatItIs: 'A fiber thickener ground from guar beans.',
    whyUsed: 'Thickens ice cream, yogurts, sauces and gluten-free flour.',
    level: AdditiveConcernLevel.low,
    whyFlagged: '',
    explanation:
        'A legume fiber your gut bacteria can actually ferment — one of the friendliest thickeners. '
        'It may even help blood sugar and fullness. No concern at food doses.',
  );

  static const AdditiveConcern _locust = AdditiveConcern(
    code: 'E410',
    category: 'Thickener',
    name: 'Locust Bean Gum (Carob Gum)',
    whatItIs: 'A thickener ground from carob seeds.',
    whyUsed: 'Gives ice cream and cream cheese a smooth, stable body.',
    level: AdditiveConcernLevel.low,
    whyFlagged: '',
    explanation:
        'A minimally processed seed fiber with a clean safety record and possible prebiotic upside. '
        'When you see it instead of polysorbate or CMC, the brand chose well.',
  );

  static const AdditiveConcern _pectin = AdditiveConcern(
    code: 'E440',
    category: 'Thickener',
    name: 'Pectin',
    whatItIs: 'The gelling fiber of apples and citrus peels.',
    whyUsed: 'Sets jams, yogurts and gummies.',
    level: AdditiveConcernLevel.low,
    whyFlagged: '',
    explanation:
        'Fruit fiber, full stop — genuinely beneficial and prebiotic. '
        'Products gelled with pectin instead of gelatin or modified starch get a quiet thumbs-up.',
  );

  static const AdditiveConcern _annatto = AdditiveConcern(
    code: 'E160b',
    category: 'Food coloring',
    name: 'Annatto',
    whatItIs: 'An orange-red color from achiote seeds.',
    whyUsed: 'Colors cheddar, butter, snacks and noodles naturally.',
    level: AdditiveConcernLevel.low,
    whyFlagged: '',
    explanation:
        'A plant color used for centuries with a good safety record — the color you want to see instead of Sunset Yellow. '
        'Rare sensitivity exists but is uncommon.',
  );

  static const AdditiveConcern _carotenes = AdditiveConcern(
    code: 'E160a',
    category: 'Food coloring',
    name: 'Carotenes',
    whatItIs: 'Orange pigments from carrots, palm or algae (pro-vitamin A).',
    whyUsed: 'Colors margarine, juices and dairy a natural orange.',
    level: AdditiveConcernLevel.low,
    whyFlagged: '',
    explanation:
        'The same pigments as carrots — nutritious color, some of which your body converts to vitamin A. '
        'Smokers should avoid high-dose beta-carotene supplements specifically, but food levels are fine.',
  );

  static const AdditiveConcern _paprika = AdditiveConcern(
    code: 'E160c',
    category: 'Food coloring',
    name: 'Paprika Extract',
    whatItIs: 'Red-orange color extracted from paprika peppers.',
    whyUsed: 'Colors sausages, snacks, sauces and noodles.',
    level: AdditiveConcernLevel.low,
    whyFlagged: '',
    explanation:
        'Spice color with antioxidant carotenoids built in. '
        'Exactly the kind of coloring a gut-friendly label should show.',
  );

  static const AdditiveConcern _curcumin = AdditiveConcern(
    code: 'E100',
    category: 'Food coloring',
    name: 'Curcumin',
    whatItIs: 'The yellow pigment of turmeric.',
    whyUsed: 'Colors mustards, drinks and sweets naturally yellow.',
    level: AdditiveConcernLevel.low,
    whyFlagged: '',
    explanation:
        'Turmeric\'s active pigment doubles as a well-studied anti-inflammatory. '
        'As a food color it is the gold standard — literally.',
  );

  static const AdditiveConcern _chlorophyll = AdditiveConcern(
    code: 'E140–E141',
    category: 'Food coloring',
    name: 'Chlorophylls',
    whatItIs: 'Green pigments from plants (E141 is the copper-stabilized form).',
    whyUsed: 'Colors pasta, sweets and drinks green.',
    level: AdditiveConcernLevel.low,
    whyFlagged: '',
    explanation:
        'Leaf-green color with a clean record — the natural alternative to Blue + Yellow dye mixes. '
        'E141\'s trace copper is far below any concern at food doses.',
  );

  static const AdditiveConcern _ascorbic = AdditiveConcern(
    code: 'E300',
    category: 'Antioxidant',
    name: 'Ascorbic Acid (Vitamin C)',
    whatItIs: 'Vitamin C used as an antioxidant preservative.',
    whyUsed: 'Stops browning in juices and dough, protects cured-meat color.',
    level: AdditiveConcernLevel.low,
    whyFlagged: '',
    explanation:
        'A vitamin doing preservative duty — it even blocks nitrosamine formation in cured meats. '
        'Seeing E300 on a label is genuinely reassuring.',
  );

  static const AdditiveConcern _tocopherols = AdditiveConcern(
    code: 'E306–E309',
    category: 'Antioxidant',
    name: 'Tocopherols (Vitamin E)',
    whatItIs: 'Vitamin E compounds from vegetable oils.',
    whyUsed: 'The safe antioxidant that stops oils and cereals going rancid.',
    level: AdditiveConcernLevel.low,
    whyFlagged: '',
    explanation:
        'The preservative you want: vitamin E protecting fats instead of BHA/BHT/TBHQ. '
        'Brands listing tocopherols chose the safe, if pricier, route.',
  );

  static const AdditiveConcern _bakingSoda = AdditiveConcern(
    code: 'E500',
    category: 'Texturizing agent',
    name: 'Sodium Carbonates (Baking Soda)',
    whatItIs: 'Good old baking soda and its cousins.',
    whyUsed: 'Leavens cakes, biscuits and batters.',
    level: AdditiveConcernLevel.low,
    whyFlagged: '',
    explanation: 'Kitchen-cupboard stuff for centuries. Adds a little sodium, nothing else to think about.',
  );

  static const AdditiveConcern _palmOil = AdditiveConcern(
    code: '',
    category: 'Fat',
    carefulFor: 'Anyone eating a lot of ultra-processed snacks — saturated fat adds up.',
    tip: 'Check biscuit and noodle labels — sunflower or rice-bran oil versions exist.',
    name: 'Palm Oil',
    whatItIs: 'A cheap semi-solid vegetable oil, ~50% saturated fat.',
    whyUsed: 'Gives instant noodles, biscuits and spreads richness without butter.',
    level: AdditiveConcernLevel.moderate,
    whyFlagged: 'High saturated fat + deforestation footprint',
    explanation:
        'Palm oil is the reason instant noodles and biscuits hit hard on saturated fat — a pro-inflammatory pattern for the gut in excess. '
        'It also carries the heaviest deforestation footprint of any food oil. Fine rarely; a daily staple it should not be.',
  );

  static const AdditiveConcern _glucoseSyrup = AdditiveConcern(
    code: '',
    category: 'Sweetener',
    name: 'Glucose Syrup',
    whatItIs: 'A syrup of glucose made by breaking down starch.',
    whyUsed: 'Sweetens and thickens sweets, sauces, drinks and baked goods cheaply.',
    level: AdditiveConcernLevel.moderate,
    whyFlagged: 'Concentrated fast sugar, spikes blood glucose',
    explanation:
        'Metabolically it is barely different from sugar — rapid glucose spikes with zero nutrition. '
        'Manufacturers love it because it is cheaper than sugar and sounds milder. Your gut and blood sugar disagree.',
  );

  static const AdditiveConcern _invertSugar = AdditiveConcern(
    code: '',
    category: 'Sweetener',
    name: 'Invert Sugar',
    whatItIs: 'Sugar pre-split into glucose and fructose.',
    whyUsed: 'Keeps sweets moist and sweet with a smoother texture.',
    level: AdditiveConcernLevel.moderate,
    whyFlagged: 'Hidden fast sugar under a technical name',
    explanation:
        'A technical-sounding name for what is essentially liquid sugar — absorbed fast, nutritionally empty. '
        'Labels use it partly because shoppers don\'t recognize it as sugar. Now you do.',
  );

  static const AdditiveConcern _maltodextrin = AdditiveConcern(
    code: '',
    category: 'Thickener',
    carefulFor: 'People with blood-sugar issues or sensitive guts.',
    name: 'Maltodextrin',
    whatItIs: 'A bland starch-derived powder (high glycemic index).',
    whyUsed: 'Bulks up snacks, sweeteners and "light" products; carries flavors.',
    level: AdditiveConcernLevel.moderate,
    whyFlagged: 'High-GI filler; linked to gut-bacteria shifts',
    explanation:
        'Maltodextrin spikes blood sugar faster than table sugar and animal studies link it to mucus-thinning and harmful E. coli growth. '
        'It hides in everything from chips to stevia packets. A reliable ultra-processing tell.',
  );

  static const AdditiveConcern _modifiedStarch = AdditiveConcern(
    code: '',
    category: 'Thickener',
    name: 'Modified Starch',
    whatItIs: 'Starch chemically or physically altered for stability.',
    whyUsed: 'Thickens soups, sauces and ready meals so they survive factories and freezers.',
    level: AdditiveConcernLevel.low,
    whyFlagged: '',
    explanation:
        'Mostly just starch engineered to behave — low direct concern, but a marker of industrial formulation. '
        'A sauce thickened with real flour or reduction beats one thickened in a lab.',
  );

  static const AdditiveConcern _yeastExtract = AdditiveConcern(
    code: '',
    category: 'Flavor enhancer',
    name: 'Yeast Extract',
    whatItIs: 'Concentrated savory compounds from yeast (natural glutamates).',
    whyUsed: 'Adds umami depth to soups, snacks and sauces without "MSG" on the label.',
    level: AdditiveConcernLevel.low,
    whyFlagged: '',
    explanation:
        'Essentially food — the savory fraction of yeast, rich in B vitamins. '
        'MSG-sensitive people may still react to its natural glutamates, but for most guts it is harmless flavor.',
  );

  static const AdditiveConcern _hvp = AdditiveConcern(
    code: '',
    category: 'Flavor enhancer',
    carefulFor: 'MSG-sensitive people — treat it exactly like MSG.',
    name: 'Hydrolyzed Vegetable Protein (HVP)',
    whatItIs: 'Vegetable protein acid-boiled into savory fragments (free glutamates).',
    whyUsed: 'A cheap umami booster behind "no added MSG" claims.',
    level: AdditiveConcernLevel.moderate,
    whyFlagged: '"No MSG" loophole: contains free glutamates',
    explanation:
        'Products can claim "no added MSG" while adding HVP, which is functionally similar free glutamate. '
        'If MSG bothers you, HVP deserves the same suspicion. Honest flavor comes from real ingredients, not hydrolysates.',
  );

  static const AdditiveConcern _naturalFlavour = AdditiveConcern(
    code: '',
    category: 'Flavoring',
    name: 'Natural Flavouring',
    whatItIs: 'A proprietary blend of flavor chemicals derived from natural sources.',
    whyUsed: 'Makes every pack taste identical, batch after batch.',
    level: AdditiveConcernLevel.low,
    whyFlagged: '',
    explanation:
        '"Natural" only describes the starting material — the blend itself is a trade secret of dozens of compounds. '
        'Generally safe, but it signals engineered, uniform flavor rather than real ingredients. Fine, not virtuous.',
  );

  /// Lookup table: normalized code OR lowercase name → concern.
  /// Built once; includes common aliases (INS numbers, spellings).
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

part of 'additive_concern_db.dart';

/// Acid and phosphate additive profiles.

const AdditiveConcern _citricAcid = AdditiveConcern(
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

const AdditiveConcern _sodiumCitrate = AdditiveConcern(
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

const AdditiveConcern _malicAcid = AdditiveConcern(
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

const AdditiveConcern _lacticAcid = AdditiveConcern(
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

const AdditiveConcern _phosphoricAcid = AdditiveConcern(
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

const AdditiveConcern _phosphates = AdditiveConcern(
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


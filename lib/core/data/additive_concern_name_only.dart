part of 'additive_concern_db.dart';

/// Name-only additive profiles.

const AdditiveConcern _palmOil = AdditiveConcern(
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

const AdditiveConcern _glucoseSyrup = AdditiveConcern(
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

const AdditiveConcern _invertSugar = AdditiveConcern(
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

const AdditiveConcern _maltodextrin = AdditiveConcern(
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

const AdditiveConcern _modifiedStarch = AdditiveConcern(
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

const AdditiveConcern _yeastExtract = AdditiveConcern(
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

const AdditiveConcern _hvp = AdditiveConcern(
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

const AdditiveConcern _naturalFlavour = AdditiveConcern(
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

part of 'additive_concern_db.dart';

/// Gum, natural-color, and baking-agent profiles.

const AdditiveConcern _xanthan = AdditiveConcern(
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

const AdditiveConcern _guar = AdditiveConcern(
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

const AdditiveConcern _locust = AdditiveConcern(
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

const AdditiveConcern _pectin = AdditiveConcern(
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

const AdditiveConcern _annatto = AdditiveConcern(
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

const AdditiveConcern _carotenes = AdditiveConcern(
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

const AdditiveConcern _paprika = AdditiveConcern(
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

const AdditiveConcern _curcumin = AdditiveConcern(
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

const AdditiveConcern _chlorophyll = AdditiveConcern(
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

const AdditiveConcern _ascorbic = AdditiveConcern(
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

const AdditiveConcern _tocopherols = AdditiveConcern(
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

const AdditiveConcern _bakingSoda = AdditiveConcern(
  code: 'E500',
  category: 'Texturizing agent',
  name: 'Sodium Carbonates (Baking Soda)',
  whatItIs: 'Good old baking soda and its cousins.',
  whyUsed: 'Leavens cakes, biscuits and batters.',
  level: AdditiveConcernLevel.low,
  whyFlagged: '',
  explanation: 'Kitchen-cupboard stuff for centuries. Adds a little sodium, nothing else to think about.',
);


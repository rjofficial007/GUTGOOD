part of 'additive_concern_db.dart';

/// Food-color additive profiles.

const AdditiveConcern _caramel4 = AdditiveConcern(
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

const AdditiveConcern _tartrazine = AdditiveConcern(
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

const AdditiveConcern _sunsetYellow = AdditiveConcern(
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

const AdditiveConcern _azorubine = AdditiveConcern(
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

const AdditiveConcern _ponceau = AdditiveConcern(
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

const AdditiveConcern _allura = AdditiveConcern(
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

const AdditiveConcern _brilliantBlue = AdditiveConcern(
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


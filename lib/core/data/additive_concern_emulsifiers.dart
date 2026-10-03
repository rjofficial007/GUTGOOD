part of 'additive_concern_db.dart';

/// Emulsifier, thickener, and stabilizer profiles.

const AdditiveConcern _carrageenan = AdditiveConcern(
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

const AdditiveConcern _cmc = AdditiveConcern(
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

const AdditiveConcern _methylcellulose = AdditiveConcern(
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

const AdditiveConcern _polysorbate = AdditiveConcern(
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

const AdditiveConcern _e471 = AdditiveConcern(
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

const AdditiveConcern _e472e = AdditiveConcern(
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

const AdditiveConcern _e476 = AdditiveConcern(
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

const AdditiveConcern _lecithin = AdditiveConcern(
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


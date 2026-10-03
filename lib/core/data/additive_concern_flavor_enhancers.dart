part of 'additive_concern_db.dart';

/// Flavor-enhancer additive profiles.

const AdditiveConcern _msg = AdditiveConcern(
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

const AdditiveConcern _e631 = AdditiveConcern(
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

const AdditiveConcern _e627 = AdditiveConcern(
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


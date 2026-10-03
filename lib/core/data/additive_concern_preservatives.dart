part of 'additive_concern_db.dart';

/// Preservative and antioxidant additive profiles.

const AdditiveConcern _sorbate = AdditiveConcern(
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

const AdditiveConcern _benzoate = AdditiveConcern(
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

const AdditiveConcern _sulphites = AdditiveConcern(
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

const AdditiveConcern _nitrite = AdditiveConcern(
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

const AdditiveConcern _nitrate = AdditiveConcern(
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

const AdditiveConcern _propionate = AdditiveConcern(
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

const AdditiveConcern _tbhq = AdditiveConcern(
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

const AdditiveConcern _bha = AdditiveConcern(
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

const AdditiveConcern _bht = AdditiveConcern(
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

const AdditiveConcern _titanium = AdditiveConcern(
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


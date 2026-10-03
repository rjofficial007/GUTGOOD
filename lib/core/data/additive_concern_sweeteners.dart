part of 'additive_concern_db.dart';

/// Sweetener additive profiles.

const AdditiveConcern _aspartame = AdditiveConcern(
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

const AdditiveConcern _acesulfame = AdditiveConcern(
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

const AdditiveConcern _sucralose = AdditiveConcern(
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

const AdditiveConcern _saccharin = AdditiveConcern(
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

const AdditiveConcern _stevia = AdditiveConcern(
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


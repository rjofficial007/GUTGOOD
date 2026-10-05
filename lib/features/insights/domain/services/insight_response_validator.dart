import 'package:gutgood/core/models/insights/body_pattern.dart';

/// Result of deterministic validation and normalization applied to an AI
/// Insight response before it is converted into the durable [AIInsight] model.
class InsightResponseValidation {
  const InsightResponseValidation({required this.data, this.reasons = const []});

  final Map<String, dynamic> data;
  final List<String> reasons;

  bool get changed => reasons.isNotEmpty;
}

/// Keeps sparse Insight responses grounded in the evidence supplied by the
/// deterministic pattern engine.
///
/// The model may write a useful narrative for a one-off observation, but it
/// must not turn that observation into a healing food, trigger, causal factor,
/// or percentage-based food-impact claim. This policy is feature-owned and is
/// intentionally independent of Flutter, Firebase, and persistence SDKs.
class InsightResponseValidator {
  const InsightResponseValidator._();

  static InsightResponseValidation normalize(Map<String, dynamic> input, {required List<BodyPattern> patternCandidates}) {
    final data = _copyMap(input);
    final reasons = <String>[];
    final qualifiedCandidates = patternCandidates.where((candidate) => candidate.frequency >= 2).toList(growable: false);
    final hasCandidates = qualifiedCandidates.isNotEmpty;

    _normalizeTopInsight(data, reasons);
    final topInsightMatched = hasCandidates && _normalizeTopInsightToCandidate(data, reasons, qualifiedCandidates);
    if (!topInsightMatched) _normalizeTopInsightWithoutCandidates(data, reasons);
    _normalizeDetectedPatterns(data, reasons, qualifiedCandidates, hasCandidates: hasCandidates);
    _normalizeHealing(data, reasons, qualifiedCandidates, hasCandidates: hasCandidates);
    _normalizeTriggers(data, reasons, qualifiedCandidates, hasCandidates: hasCandidates);

    if (!hasCandidates) {
      data['foodImpacts'] = <dynamic>[];
      data['foodSwaps'] = <dynamic>[];
      data['actions'] = <dynamic>[];
      _setEmptyBalance(data);
      data
        ..remove('topHealing')
        ..remove('topTrigger')
        ..remove('improving')
        ..remove('watch')
        ..remove('smartSwap');
      reasons.add('no qualified pattern candidates: removed derived food-impact sections');
    } else {
      _normalizeFoodSwaps(data, reasons, qualifiedCandidates);
      _normalizeFoodImpacts(data, reasons, qualifiedCandidates);
      _normalizeFoodImpactBalance(data, reasons);
      _normalizeTopHighlight(data, reasons, 'topHealing', candidates: qualifiedCandidates, positive: true);
      _normalizeTopHighlight(data, reasons, 'topTrigger', candidates: qualifiedCandidates, positive: false);
      _normalizeTopFoodId(data, 'healing');
      _normalizeTopFoodId(data, 'triggers');
    }

    return InsightResponseValidation(data: data, reasons: reasons);
  }

  static void _normalizeTopInsight(Map<String, dynamic> data, List<String> reasons) {
    final top = _asMap(data['topInsight']);
    if (top == null) return;

    // `type` is the canonical model field. `kind` is accepted for tolerant
    // reads because older prompt examples used that name.
    if (!top.containsKey('type') && top['kind'] != null) {
      top['type'] = top['kind'];
      reasons.add('mapped topInsight.kind to topInsight.type');
    }

    final rawConfidence = top['confidence'];
    final rawScore = _number(top['confidenceScore']) ?? (rawConfidence is num ? rawConfidence : null);
    if (rawScore != null) {
      top['confidenceScore'] = _clamp01(rawScore);
      final normalizedLabel = _confidenceLabel(rawScore);
      if (rawConfidence == null || rawConfidence.toString().toLowerCase() != normalizedLabel) {
        top['confidence'] = normalizedLabel;
        reasons.add('normalized topInsight confidence to match confidenceScore');
      }
    }

    if (top['strength'] == null && top['confidence'] is String) {
      top['strength'] = top['confidence'];
    }

    final frequency = _integer(top['frequency']);
    if (frequency != null && frequency <= 1) {
      top['strength'] = 'low';
      top['confidence'] = 'low';
      final existingScore = _number(top['confidenceScore']) ?? 0.5;
      top['confidenceScore'] = _clamp01(existingScore > 0.5 ? 0.5 : existingScore);
      final description = top['description']?.toString() ?? '';
      final lowerDescription = description.toLowerCase();
      if (description.isNotEmpty &&
          !lowerDescription.contains('not a confirmed') &&
          !lowerDescription.contains('early observation') &&
          !lowerDescription.contains('not enough evidence')) {
        top['description'] = '$description This is an early observation, not a confirmed food pattern.';
      }
      reasons.add('capped one-occurrence topInsight confidence at low');
    }

    data['topInsight'] = top;
  }

  static void _normalizeTopInsightWithoutCandidates(Map<String, dynamic> data, List<String> reasons) {
    final top = _asMap(data['topInsight']);
    if (top == null) return;

    final type = top['type']?.toString().toLowerCase();
    if (type == 'pattern' || type == 'food_impact' || type == 'trigger_alert') {
      top['type'] = 'progress';
      reasons.add('downgraded causal topInsight type without qualified candidates');
    }
    top['strength'] = 'low';
    top['confidence'] = 'low';
    final existingScore = _number(top['confidenceScore']) ?? 0.5;
    top['confidenceScore'] = _clamp01(existingScore > 0.5 ? 0.5 : existingScore);
    top['frequency'] = 1;
    top
      ..remove('evidenceRatio')
      ..remove('positiveCount')
      ..remove('negativeCount');
    top['description'] = 'This is an early observation. More logs are needed before confirming a repeated food pattern.';
    top['observation'] = top['description'];
    reasons.add('topInsight had no matching qualified pattern: capped frequency and removed unsupported repetition claims');
    data['topInsight'] = top;
  }

  static bool _normalizeTopInsightToCandidate(Map<String, dynamic> data, List<String> reasons, List<BodyPattern> candidates) {
    final top = _asMap(data['topInsight']);
    if (top == null) return false;
    final candidate = _matchingCandidate(top, candidates);
    if (candidate == null) return false;

    top
      ..['domain'] = candidate.type
      ..['involvedFoods'] = candidate.involvedFoods
      ..['frequency'] = candidate.frequency
      ..['evidenceRatio'] = candidate.evidenceRatio
      ..['positiveCount'] = candidate.positiveCount
      ..['negativeCount'] = candidate.negativeCount
      ..['strength'] = _candidateConfidence(candidate, candidate.frequency)
      ..['confidence'] = _candidateConfidence(candidate, candidate.frequency)
      ..['confidenceScore'] = candidate.frequency <= 1 ? 0.5 : _candidateConfidenceScore(candidate)
      ..['description'] = candidate.description
      ..['observation'] = candidate.description;
    data['topInsight'] = top;
    reasons.add('grounded topInsight frequency and narrative in matching deterministic pattern');
    return true;
  }

  static void _normalizeDetectedPatterns(Map<String, dynamic> data, List<String> reasons, List<BodyPattern> candidates, {required bool hasCandidates}) {
    final raw = data['detectedPatterns'];
    if (!hasCandidates) {
      if (raw is List && raw.isNotEmpty) {
        reasons.add('removed detectedPatterns without qualified candidates');
      }
      data['detectedPatterns'] = <dynamic>[];
      return;
    }

    if (raw is! List) return;
    final normalized = <Map<String, dynamic>>[];
    for (final item in raw) {
      final pattern = _asMap(item);
      if (pattern == null) continue;
      final candidate = _matchingCandidate(pattern, candidates);
      if (candidate == null) {
        reasons.add('removed detected pattern without a matching qualified candidate');
        continue;
      }

      // Candidate fields are produced by the deterministic pattern engine.
      // Copy the evidence-bearing fields back over the model's free-form
      // versions so it cannot invent timing, factors, or counts.
      pattern
        ..['type'] = candidate.type
        ..['domain'] = candidate.type
        ..['trigger'] = candidate.trigger
        ..['reaction'] = candidate.reaction
        ..['frequency'] = candidate.frequency
        ..['involvedFoods'] = candidate.involvedFoods
        ..['relatedFoodIds'] = candidate.relatedFoodIds
        ..['totalSimilarMeals'] = candidate.totalSimilarMeals
        ..['timeframeDays'] = candidate.timeframeDays
        ..['evidenceRatio'] = candidate.evidenceRatio
        ..['positiveCount'] = candidate.positiveCount
        ..['negativeCount'] = candidate.negativeCount
        ..['impactDirection'] = candidate.impactDirection
        ..['commonFactors'] = candidate.commonFactors.map((factor) => factor.toMap()).toList()
        ..['occurrences'] = candidate.occurrences.map((occurrence) => occurrence.toMap()).toList();
      pattern['description'] = candidate.description;
      pattern['recommendation'] = candidate.recommendation;
      pattern['typicalTiming'] = candidate.typicalTiming;
      pattern['typicalDelay'] = candidate.typicalDelay;

      final frequency = candidate.frequency;
      pattern['confidence'] = _candidateConfidence(candidate, frequency);
      pattern['confidenceScore'] = frequency <= 1 ? 0.5 : _candidateConfidenceScore(candidate);
      pattern['impactLevel'] = frequency <= 1 ? 'low' : _candidateImpactLevel(candidate);
      if (frequency <= 1) {
        pattern['commonFactors'] = <dynamic>[];
        pattern['occurrences'] = <dynamic>[];
        reasons.add('capped one-occurrence detected pattern confidence and impact');
      }
      normalized.add(pattern);
    }
    data['detectedPatterns'] = normalized;
  }

  static void _normalizeHealing(Map<String, dynamic> data, List<String> reasons, List<BodyPattern> candidates, {required bool hasCandidates}) {
    final healing = _asMap(data['healing']);
    if (healing == null) {
      if (!hasCandidates) {
        data['healingFoods'] = <dynamic>[];
      } else {
        data['healingFoods'] = _normalizeSparseFoods(data['healingFoods'], reasons, candidates: candidates, positive: true);
      }
      return;
    }

    if (!hasCandidates) {
      data['healing'] = {
        'goal': healing['goal']?.toString() ?? '',
        'trend': 'No repeated pattern yet',
        'topFoodId': '',
        'foods': <dynamic>[],
      };
      data['healingFoods'] = <dynamic>[];
      reasons.add('removed healing foods without qualified candidates');
      return;
    }

    final healingFoods = _normalizeSparseFoods(healing['foods'], reasons, candidates: candidates, positive: true);
    healing['foods'] = healingFoods;
    if (healingFoods.isEmpty) {
      healing['topFoodId'] = '';
      healing['trend'] = 'No supported healing pattern yet';
    }
    data['healing'] = healing;
    // Keep the legacy top-level fields aligned with the validated nested block.
    data['healingGoal'] = healing['goal']?.toString() ?? '';
    data['healingTrend'] = healing['trend']?.toString() ?? '';
    data['healingFoods'] = healingFoods;
  }

  static void _normalizeTriggers(Map<String, dynamic> data, List<String> reasons, List<BodyPattern> candidates, {required bool hasCandidates}) {
    final triggers = _asMap(data['triggers']);
    if (triggers == null) {
      if (!hasCandidates) {
        data['triggerFoods'] = <dynamic>[];
      } else {
        data['triggerFoods'] = _normalizeSparseFoods(data['triggerFoods'], reasons, candidates: candidates, positive: false);
      }
      return;
    }

    if (!hasCandidates) {
      data['triggers'] = {
        'primarySymptom': '',
        'trend': '',
        'topFoodId': '',
        'foods': <dynamic>[],
      };
      data['triggerFoods'] = <dynamic>[];
      reasons.add('removed trigger foods without qualified candidates');
      return;
    }

    var triggerFoods = _normalizeSparseFoods(triggers['foods'], reasons, candidates: candidates, positive: false);
    if (triggerFoods.isEmpty) {
      triggerFoods = [
        for (final candidate in candidates.where((candidate) => _candidateSupportsDirection(candidate, false)))
          {
            'foodId': _canonicalFoodId(candidate.trigger),
            'name': candidate.trigger,
            'effect': candidate.reaction,
            'impactDirection': 'negative',
            'impactLevel': _candidateImpactLevel(candidate),
            'frequencyCount': candidate.frequency,
            'frequencyLabel': '${candidate.frequency} occurrences',
            'confidence': _candidateConfidence(candidate, candidate.frequency),
            'confidenceScore': _candidateConfidenceScore(candidate),
          },
      ];
      if (triggerFoods.isNotEmpty) reasons.add('restored trigger foods from qualified negative patterns');
    }
    triggers['foods'] = triggerFoods;
    if (triggerFoods.isEmpty) {
      triggers['topFoodId'] = '';
      triggers['trend'] = 'No supported trigger pattern yet';
    } else if (!triggerFoods.any((food) => (food as Map<String, dynamic>)['foodId'] == triggers['topFoodId'])) {
      triggers['topFoodId'] = (triggerFoods.first as Map<String, dynamic>)['foodId'];
    }
    data['triggers'] = triggers;
    // Keep the legacy top-level fields aligned with the validated nested block.
    data['triggerSymptom'] = triggers['primarySymptom']?.toString() ?? '';
    data['triggerTrend'] = triggers['trend']?.toString() ?? '';
    data['triggerFoods'] = triggerFoods;
  }

  static List<dynamic> _normalizeSparseFoods(Object? value, List<String> reasons, {required List<BodyPattern> candidates, required bool positive}) {
    if (value is! List) return <dynamic>[];
    final normalized = <Map<String, dynamic>>[];
    for (final item in value) {
      final food = _asMap(item);
      if (food == null) continue;
      final candidate = _matchingCandidate(food, candidates, positive: positive);
      if (candidate == null) {
        reasons.add('removed food impact without a matching qualified candidate');
        continue;
      }

      if (_candidateIsComposite(candidate)) {
        food['name'] = candidate.trigger;
        food['foodId'] = _canonicalFoodId(candidate.trigger);
      }
      final reportedFrequency = _integer(food['frequencyCount']);
      final frequency = reportedFrequency == null || reportedFrequency > candidate.frequency ? candidate.frequency : reportedFrequency;
      food['frequencyCount'] = frequency;
      food['frequencyLabel'] = frequency == 1 ? '1 occurrence' : '$frequency occurrences';
      food['confidence'] = _candidateConfidence(candidate, frequency);
      food['confidenceScore'] = frequency <= 1 ? 0.5 : _candidateConfidenceScore(candidate);
      food['impactLevel'] = frequency <= 1 ? 'low' : _candidateImpactLevel(candidate);
      food['impactDirection'] = positive == true ? 'positive' : positive == false ? 'negative' : candidate.impactDirection;
      food['effect'] = candidate.reaction;
      food['observedEffect'] = candidate.reaction;
      food['bestTimeLabel'] = candidate.typicalTiming ?? '';
      if (!_hasSupportedMechanism(food, candidate)) {
        for (final key in ['whyItWorks', 'pairings', 'structuredBenefits', 'reason', 'whyBetterOption', 'mechanism', 'mechanismDetails', 'causalFactors']) {
          food.remove(key);
        }
        reasons.add('removed unsupported mechanism details from food impact');
      }
      if (frequency <= 1) {
        food['whyItWorks'] = <dynamic>[];
        food['pairings'] = <dynamic>[];
        reasons.add('capped one-occurrence food impact at low confidence');
      }
      normalized.add(food);
    }
    return normalized;
  }

  static String _candidateConfidence(BodyPattern candidate, int frequency) {
    if (frequency <= 1) return 'low';
    final confidence = candidate.confidence.toLowerCase();
    if (confidence == 'high') return 'high';
    if (confidence == 'medium' || confidence == 'moderate') return 'medium';
    return 'low';
  }

  static double _candidateConfidenceScore(BodyPattern candidate) {
    if (candidate.confidenceScore > 0) return _clamp01(candidate.confidenceScore);
    switch (_candidateConfidence(candidate, candidate.frequency)) {
      case 'high':
        return 0.85;
      case 'medium':
        return 0.65;
      default:
        return 0.5;
    }
  }

  static String _candidateImpactLevel(BodyPattern candidate) {
    final impact = candidate.impactLevel.toLowerCase();
    if (impact == 'high' || impact == 'moderate' || impact == 'low') return impact;
    switch (_candidateConfidence(candidate, candidate.frequency)) {
      case 'high':
        return 'high';
      case 'medium':
        return 'moderate';
      default:
        return 'low';
    }
  }

  static bool _hasSupportedMechanism(Map<String, dynamic> food, BodyPattern candidate) {
    final claims = <String>[];
    for (final key in ['whyItWorks', 'pairings', 'structuredBenefits', 'reason', 'whyBetterOption', 'mechanism', 'mechanismDetails', 'causalFactors']) {
      final value = food[key];
      if (value is String && value.trim().isNotEmpty) claims.add(value.toLowerCase());
      if (value is List) {
        for (final item in value) {
          if (item is Map) {
            final text = [item['title'], item['description'], item['label'], item['name'], item['food']].whereType<Object>().join(' ').trim();
            if (text.isNotEmpty) claims.add(text.toLowerCase());
          } else if (item != null && item.toString().trim().isNotEmpty) {
            claims.add(item.toString().toLowerCase());
          }
        }
      }
    }
    if (claims.isEmpty) return true;

    final evidence = [
      candidate.description,
      candidate.reaction,
      ...candidate.commonFactors.map((factor) => factor.label),
      ...candidate.occurrences.expand((occurrence) => occurrence.commonFactors.map((factor) => factor.label)),
    ].join(' ').toLowerCase();
    return claims.every((claim) {
      final words = claim.split(RegExp('[^a-z0-9]+')).where((word) => word.length >= 4).toList();
      return words.isNotEmpty && words.every(evidence.contains);
    });
  }

  static bool _candidateIsComposite(BodyPattern candidate) =>
      candidate.involvedFoods.map(_foodKey).where((key) => key.isNotEmpty).toSet().length > 1 || RegExp(r'(\+|&|,|\band\b)', caseSensitive: false).hasMatch(candidate.trigger);

  static BodyPattern? _matchingCandidate(Map<String, dynamic> value, List<BodyPattern> candidates, {bool? positive}) {
    if (candidates.isEmpty) return null;

    final valueKeys = <String>{};
    for (final key in ['foodId', 'name', 'food', 'title', 'trigger']) {
      final text = value[key]?.toString() ?? '';
      final normalized = _foodKey(text);
      if (normalized.isNotEmpty) valueKeys.add(normalized);
    }
    final valueInvolved = <String>{};
    final involved = value['involvedFoods'];
    if (involved is List) {
      for (final item in involved) {
        final normalized = _foodKey(item?.toString() ?? '');
        if (normalized.isNotEmpty) {
          valueKeys.add(normalized);
          valueInvolved.add(normalized);
        }
      }
    }

    final valueDomain = _foodKey((value['domain'] ?? value['type'])?.toString() ?? '');
    for (final candidate in candidates) {
      if (!_candidateSupportsDirection(candidate, positive)) continue;

      final triggerKey = _foodKey(candidate.trigger);
      final involvedKeys = candidate.involvedFoods.map(_foodKey).where((key) => key.isNotEmpty).toSet();
      final isComposite = _candidateIsComposite(candidate);

      // A pattern engine candidate that contains several foods represents a
      // meal combination. A single food in the response must not be accepted
      // as an independently causal match for that candidate.
      if (isComposite) {
        final exactComposite = triggerKey.isNotEmpty && valueKeys.contains(triggerKey);
        final completeComposite = involvedKeys.isNotEmpty && valueInvolved.containsAll(involvedKeys);
        if (exactComposite || completeComposite) return candidate;
        continue;
      }

      final candidateKeys = <String>{
        triggerKey,
        ...involvedKeys,
        ...candidate.relatedFoodIds.map(_foodKey),
      }..removeWhere((key) => key.isEmpty);
      final sameFood = valueKeys.any((key) => candidateKeys.any((candidateKey) => key == candidateKey || key.contains(candidateKey) || candidateKey.contains(key)));
      if (sameFood || (valueKeys.isEmpty && valueDomain.isNotEmpty && valueDomain == _foodKey(candidate.type))) return candidate;
    }
    return null;
  }

  static bool _candidateSupportsDirection(BodyPattern candidate, bool? positive) {
    if (positive == null) return true;
    final explicit = candidate.impactDirection.toLowerCase();
    if (explicit == 'positive') return positive;
    if (explicit == 'negative') return !positive;

    final reaction = '${candidate.reaction} ${candidate.description}'.toLowerCase();
    if (RegExp(r'\b(bloat(?:ing)?|headache|pain|fatigue|sluggish|sleepy|nausea|negative|drop|low|hunger|hungry|discomfort|poor|interrupted)\b').hasMatch(reaction)) return !positive;
    if (RegExp(r'\b(energ(y|ized)|refreshed|comfortable|comfort|positive|good|great|steady|balanced|satiet(y|ed)|satisfied|wellness|better)\b').hasMatch(reaction)) return positive;
    return false;
  }

  static String _foodKey(String value) => value.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), ' ').trim();

  static String _canonicalFoodId(String value) => _foodKey(value).replaceAll(' ', '_');

  static void _normalizeFoodSwaps(Map<String, dynamic> data, List<String> reasons, List<BodyPattern> candidates) {
    final rawSwaps = data['foodSwaps'];
    if (rawSwaps is! List) {
      data['foodSwaps'] = <dynamic>[];
      return;
    }

    final normalized = <Map<String, dynamic>>[];
    for (final item in rawSwaps) {
      final swap = _asMap(item);
      final source = swap == null ? null : _asMap(swap['source']);
      if (swap == null || source == null) continue;
      final candidate = _matchingCandidate(source, candidates, positive: false);
      if (candidate == null || candidate.frequency <= 1) {
        reasons.add('removed food swap without repeated negative evidence');
        continue;
      }
      if (_candidateIsComposite(candidate)) {
        source['name'] = candidate.trigger;
        source['foodId'] = _canonicalFoodId(candidate.trigger);
      }

      // Swap benefits compare the alternative with its source. Pattern
      // evidence describes the user's reaction, so matching benefit text
      // against it incorrectly removes valid swap details.
      if (candidate.id != null && candidate.id!.isNotEmpty) swap['relatedPatternId'] = candidate.id;
      normalized.add(swap);
    }
    data['foodSwaps'] = normalized;
  }

  static void _normalizeFoodImpacts(Map<String, dynamic> data, List<String> reasons, List<BodyPattern> candidates) {
    final rawImpacts = data['foodImpacts'];
    if (rawImpacts is! List) {
      data['foodImpacts'] = <dynamic>[];
      return;
    }

    final normalized = <Map<String, dynamic>>[];
    for (final item in rawImpacts) {
      final impact = _asMap(item);
      if (impact == null) continue;
      final direction = (impact['impactDirection'] ?? impact['impactType'] ?? impact['type'] ?? '').toString().toLowerCase();
      final positive = direction == 'positive' ? true : direction == 'negative' ? false : null;
      final candidate = _matchingCandidate(impact, candidates, positive: positive);
      if (candidate == null) {
        reasons.add('removed food impact without a matching qualified candidate');
        continue;
      }

      if (_candidateIsComposite(candidate)) impact['food'] = candidate.trigger;
      final frequency = _integer(impact['frequencyCount']) ?? candidate.frequency;
      impact['frequencyCount'] = frequency;
      impact['impactLevel'] = frequency <= 1 ? 'low' : _candidateImpactLevel(candidate);
      impact['confidence'] = frequency <= 1 ? 'low' : _candidateConfidence(candidate, frequency);
      impact['confidenceScore'] = frequency <= 1 ? 0.5 : _candidateConfidenceScore(candidate);
      impact['impactDirection'] = positive == null ? candidate.impactDirection : positive ? 'positive' : 'negative';
      impact['impactType'] = impact['impactDirection'];
      impact['effect'] = candidate.reaction;
      if (frequency <= 1) {
        // Keep the event as a neutral observation, but do not let the model's
        // wording turn it into a positive/negative percentage or a causal
        // explanation. FoodImpact.fromMap honors this explicit neutral type.
        impact['impactDirection'] = 'neutral';
        impact['impactType'] = 'neutral';
        impact['type'] = 'neutral';
        impact['impactLevel'] = 'low';
        impact['confidence'] = 'low';
        impact['confidenceScore'] = 0.5;
        impact['effect'] = 'Observed once; direction is not established.';
        reasons.add('capped one-occurrence food impact at neutral and low confidence');
      }
      normalized.add(impact);
    }
    data['foodImpacts'] = normalized;
  }

  static void _normalizeFoodImpactBalance(Map<String, dynamic> data, List<String> reasons) {
    final impacts = data['foodImpacts'];
    if (impacts is! List || impacts.isEmpty) {
      _setEmptyBalance(data);
      reasons.add('cleared foodImpactBalance because no food impacts were supplied');
      return;
    }

    var positive = 0;
    var negative = 0;
    var neutral = 0;
    for (final item in impacts) {
      final impact = _asMap(item);
      final direction = (impact?['impactDirection'] ?? impact?['impactType'] ?? impact?['type'] ?? '').toString().toLowerCase();
      if (direction == 'positive') {
        positive++;
      } else if (direction == 'negative') {
        negative++;
      } else {
        neutral++;
      }
    }

    final total = positive + negative + neutral;
    if (total == 0) {
      _setEmptyBalance(data);
      return;
    }

    final percentages = _balancedPercentages([positive, neutral, negative], total);
    data['foodImpactBalance'] = {
      'positivePercent': percentages[0],
      'neutralPercent': percentages[1],
      'negativePercent': percentages[2],
      'periodLabel': _asMap(data['foodImpactBalance'])?['periodLabel']?.toString() ?? 'Last 4 weeks',
    };
    reasons.add('recalculated foodImpactBalance from foodImpacts');
  }

  static List<int> _balancedPercentages(List<int> counts, int total) {
    final exact = counts.map((count) => count * 100 / total).toList();
    final percentages = exact.map((value) => value.floor()).toList();
    var remainder = 100 - percentages.fold<int>(0, (sum, value) => sum + value);
    final order = List<int>.generate(counts.length, (index) => index)..sort((a, b) => (exact[b] - exact[b].floor()).compareTo(exact[a] - exact[a].floor()));
    var cursor = 0;
    while (remainder > 0 && order.isNotEmpty) {
      percentages[order[cursor % order.length]]++;
      cursor++;
      remainder--;
    }
    return percentages;
  }

  static void _normalizeTopHighlight(
    Map<String, dynamic> data,
    List<String> reasons,
    String field, {
    required List<BodyPattern> candidates,
    required bool positive,
  }) {
    final highlight = _asMap(data[field]);
    if (highlight == null) return;
    final candidate = _matchingCandidate(highlight, candidates, positive: positive);
    if (candidate == null) {
      data.remove(field);
      reasons.add('removed $field without a matching qualified candidate');
      return;
    }
    highlight['food'] = candidate.trigger;
    highlight['frequency'] = '${candidate.frequency}x';
    highlight['effects'] = candidate.reaction;
    data[field] = highlight;
  }

  static void _normalizeTopFoodId(Map<String, dynamic> data, String sectionName) {
    final section = _asMap(data[sectionName]);
    if (section == null) return;
    final foods = section['foods'];
    if (foods is! List) return;
    final ids = foods.map(_asMap).whereType<Map<String, dynamic>>().map((food) => food['foodId']?.toString()).whereType<String>().toSet();
    final topFoodId = section['topFoodId']?.toString() ?? '';
    if (topFoodId.isNotEmpty && !ids.contains(topFoodId)) {
      section['topFoodId'] = '';
      data[sectionName] = section;
    }
  }

  static void _setEmptyBalance(Map<String, dynamic> data) {
    final previous = _asMap(data['foodImpactBalance']);
    data['foodImpactBalance'] = {
      'positivePercent': 0,
      'neutralPercent': 0,
      'negativePercent': 0,
      'periodLabel': previous?['periodLabel']?.toString() ?? 'Last 4 weeks',
    };
  }

  static Map<String, dynamic> _copyMap(Map<String, dynamic> source) {
    final copy = <String, dynamic>{};
    source.forEach((key, value) {
      if (value is Map) {
        copy[key] = _copyMap(Map<String, dynamic>.from(value));
      } else if (value is List) {
        copy[key] = value.map((item) {
          if (item is Map) return _copyMap(Map<String, dynamic>.from(item));
          if (item is List) return item.toList();
          return item;
        }).toList();
      } else {
        copy[key] = value;
      }
    });
    return copy;
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  static int? _integer(Object? value) => value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

  static double? _number(Object? value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');

  static double _clamp01(num value) => value.toDouble().clamp(0.0, 1.0).toDouble();

  static String _confidenceLabel(num value) {
    final score = _clamp01(value);
    if (score >= 0.8) return 'high';
    if (score >= 0.6) return 'medium';
    return 'low';
  }
}

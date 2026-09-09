import 'package:equatable/equatable.dart';
import 'package:gutgood/core/utils/date_time_utils.dart';
import 'package:gutgood/core/utils/model_utils.dart';

/// Link buckets answering "which logs share this photo" (P1-3e).
class FoodImageLinks extends Equatable {
  const FoodImageLinks({this.chat = const [], this.scans = const [], this.meals = const [], this.symptoms = const []});

  factory FoodImageLinks.fromMap(Map<String, dynamic>? map) => FoodImageLinks(
    chat: ModelUtils.parseList<String>(map?['chat']),
    scans: ModelUtils.parseList<String>(map?['scans']),
    meals: ModelUtils.parseList<String>(map?['meals']),
    symptoms: ModelUtils.parseList<String>(map?['symptoms']),
  );

  static const kindChat = 'chat';
  static const kindScan = 'scans';
  static const kindMeal = 'meals';
  static const kindSymptom = 'symptoms';

  /// Chat message localIds referencing this photo.
  final List<String> chat;

  /// scan_history doc ids referencing this photo.
  final List<String> scans;

  /// journal_logs meal doc ids referencing this photo.
  final List<String> meals;

  /// journal_logs symptom doc ids referencing this photo.
  final List<String> symptoms;

  Map<String, dynamic> toMap() => {'chat': chat, 'scans': scans, 'meals': meals, 'symptoms': symptoms};

  int get total => chat.length + scans.length + meals.length + symptoms.length;
  bool get isEmpty => total == 0;

  FoodImageLinks addLink(String kind, String id) {
    switch (kind) {
      case kindChat:
        return chat.contains(id) ? this : FoodImageLinks(chat: [...chat, id], scans: scans, meals: meals, symptoms: symptoms);
      case kindScan:
        return scans.contains(id) ? this : FoodImageLinks(chat: chat, scans: [...scans, id], meals: meals, symptoms: symptoms);
      case kindMeal:
        return meals.contains(id) ? this : FoodImageLinks(chat: chat, scans: scans, meals: [...meals, id], symptoms: symptoms);
      case kindSymptom:
        return symptoms.contains(id) ? this : FoodImageLinks(chat: chat, scans: scans, meals: meals, symptoms: [...symptoms, id]);
      default:
        return this;
    }
  }

  FoodImageLinks removeLink(String kind, String id) {
    switch (kind) {
      case kindChat:
        return chat.contains(id) ? FoodImageLinks(chat: chat.where((e) => e != id).toList(), scans: scans, meals: meals, symptoms: symptoms) : this;
      case kindScan:
        return scans.contains(id) ? FoodImageLinks(chat: chat, scans: scans.where((e) => e != id).toList(), meals: meals, symptoms: symptoms) : this;
      case kindMeal:
        return meals.contains(id) ? FoodImageLinks(chat: chat, scans: scans, meals: meals.where((e) => e != id).toList(), symptoms: symptoms) : this;
      case kindSymptom:
        return symptoms.contains(id) ? FoodImageLinks(chat: chat, scans: scans, meals: meals, symptoms: symptoms.where((e) => e != id).toList()) : this;
      default:
        return this;
    }
  }

  @override
  List<Object?> get props => [chat, scans, meals, symptoms];
}

/// Metadata record for one deduplicated food photo (audit §E).
///
/// Lives at `user_profiles/{uid}/food_images/{sha256_16}`. The doc — not the
/// bare URL strings copied into chat/journal docs — is the source of truth
/// for the image lifecycle: dedup, thumbnails, link tracking, and orphan
/// sweeping all key off it.
class FoodImage extends Equatable {
  const FoodImage({
    required this.hash,
    required this.storagePath,
    this.downloadUrl,
    this.thumbPath,
    this.thumbUrl,
    this.width,
    this.height,
    this.bytes,
    this.links = const FoodImageLinks(),
    this.linkCount = 0,
    this.lastUnlinkedAt,
    this.foods = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory FoodImage.fromMap(Map<String, dynamic> map) => FoodImage(
    hash: (map['hash'] ?? '').toString(),
    storagePath: (map['storagePath'] ?? '').toString(),
    downloadUrl: map['downloadUrl'] as String?,
    thumbPath: map['thumbPath'] as String?,
    thumbUrl: map['thumbUrl'] as String?,
    width: (map['width'] as num?)?.toInt(),
    height: (map['height'] as num?)?.toInt(),
    bytes: (map['bytes'] as num?)?.toInt(),
    links: FoodImageLinks.fromMap(map['links'] as Map<String, dynamic>?),
    linkCount: (map['linkCount'] as num?)?.toInt() ?? 0,
    lastUnlinkedAt: map['lastUnlinkedAt'] == null ? null : DateTimeUtils.parse(map['lastUnlinkedAt']),
    foods: ModelUtils.parseList<String>(map['foods']),
    createdAt: map['createdAt'] == null ? null : DateTimeUtils.parse(map['createdAt']),
    updatedAt: map['updatedAt'] == null ? null : DateTimeUtils.parse(map['updatedAt']),
  );

  /// sha256_16 content hash; also the doc id and Storage filename stem.
  final String hash;

  /// Canonical Storage path (`users/{uid}/food_images/{hash}.jpg`).
  final String storagePath;

  /// Cached full-size download URL (tokens don't expire; refreshed on re-register).
  final String? downloadUrl;

  /// Server-generated 320px thumbnail (`.../thumbs/{hash}.jpg`), backfilled by function.
  final String? thumbPath;
  final String? thumbUrl;

  /// Pixel dimensions + stored bytes, backfilled by the thumbnail function.
  final int? width;
  final int? height;
  final int? bytes;

  final FoodImageLinks links;

  /// Denormalized links.total for the sweeper query (maintained transactionally).
  final int linkCount;

  /// When the doc last became unlinked (sweeper grace anchor; absent while linked).
  final DateTime? lastUnlinkedAt;

  /// Normalized dish names visible in this photo (audit §E image+food pairing).
  final List<String> foods;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() => {
    'hash': hash,
    'storagePath': storagePath,
    'downloadUrl': downloadUrl,
    'thumbPath': thumbPath,
    'thumbUrl': thumbUrl,
    'width': width,
    'height': height,
    'bytes': bytes,
    'links': links.toMap(),
    'linkCount': linkCount,
    'lastUnlinkedAt': lastUnlinkedAt == null ? null : DateTimeUtils.toTimestamp(lastUnlinkedAt!),
    'foods': foods,
    'createdAt': createdAt == null ? null : DateTimeUtils.toTimestamp(createdAt!),
    'updatedAt': updatedAt == null ? null : DateTimeUtils.toTimestamp(updatedAt!),
  };

  @override
  List<Object?> get props => [hash, storagePath, downloadUrl, thumbPath, thumbUrl, width, height, bytes, links, linkCount, lastUnlinkedAt, foods, createdAt, updatedAt];
}

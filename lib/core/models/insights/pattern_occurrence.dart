import 'package:equatable/equatable.dart';

class PatternOccurrence extends Equatable {
  const PatternOccurrence({required this.date, required this.mealName, this.imageUrl, required this.reaction, required this.timeAfter});

  factory PatternOccurrence.fromMap(Map<String, dynamic> map) =>
      PatternOccurrence(date: map['date'] ?? '', mealName: map['mealName'] ?? '', imageUrl: map['imageUrl'], reaction: map['reaction'] ?? '', timeAfter: map['timeAfter'] ?? '');

  final String date;
  final String mealName;
  final String? imageUrl;
  final String reaction;
  final String timeAfter;

  Map<String, dynamic> toMap() => {'date': date, 'mealName': mealName, 'imageUrl': imageUrl, 'reaction': reaction, 'timeAfter': timeAfter};

  @override
  List<Object?> get props => [date, mealName, imageUrl, reaction, timeAfter];
}

class CommonFactor extends Equatable {
  const CommonFactor({required this.label, required this.icon});

  factory CommonFactor.fromMap(Map<String, dynamic> map) => CommonFactor(label: map['label'] ?? '', icon: map['icon'] ?? '');

  final String label;
  final String icon;

  Map<String, dynamic> toMap() => {'label': label, 'icon': icon};

  @override
  List<Object?> get props => [label, icon];
}

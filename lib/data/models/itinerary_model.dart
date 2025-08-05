import 'dart:convert';
import 'package:hive/hive.dart';

part 'itinerary_model.g.dart';

@HiveType(typeId: 2)
class Itinerary {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String startDate;

  @HiveField(2)
  final String endDate;

  @HiveField(3)
  final List<Day> days;

  Itinerary({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.days,
  });

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      title: json['title'] as String,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      days: (json['days'] as List<dynamic>)
          .map((dayJson) => Day.fromJson(dayJson as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'startDate': startDate,
      'endDate': endDate,
      'days': days.map((day) => day.toJson()).toList(),
    };
  }
}

@HiveType(typeId: 3)
class Day {
  @HiveField(0)
  final String date;

  @HiveField(1)
  final String summary;

  @HiveField(2)
  final List<ActivityItem> items;

  Day({
    required this.date,
    required this.summary,
    required this.items,
  });

  factory Day.fromJson(Map<String, dynamic> json) {
    return Day(
      date: json['date'] as String,
      summary: json['summary'] as String,
      items: (json['items'] as List<dynamic>)
          .map((itemJson) =>
              ActivityItem.fromJson(itemJson as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'summary': summary,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

@HiveType(typeId: 4)
class ActivityItem {
  @HiveField(0)
  final String time;

  @HiveField(1)
  final String activity;

  @HiveField(2)
  final String location;

  ActivityItem({
    required this.time,
    required this.activity,
    required this.location,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      time: json['time'] as String,
      activity: json['activity'] as String,
      location: json['location'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'activity': activity,
      'location': location,
    };
  }
}

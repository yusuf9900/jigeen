import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String title;
  final String description;
  final String region;
  final String commune;
  final String location; // For combined display
  final String type;
  final Timestamp timestamp;
  final String? imagePath;
  final bool isUrgent;
  final bool isAnonymous;
  final bool isTestimony;

  Report({
    required this.id,
    required this.title,
    required this.description,
    required this.region,
    required this.commune,
    required this.location,
    required this.type,
    required this.timestamp,
    this.imagePath,
    this.isUrgent = false,
    this.isAnonymous = false,
    this.isTestimony = false,
  });

  factory Report.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Report(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      region: data['region'] ?? '',
      commune: data['commune'] ?? '',
      location: data['location'] ?? '',
      type: data['type'] ?? 'Autre',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      imagePath: data['imagePath'],
      isUrgent: data['isUrgent'] ?? false,
      isAnonymous: data['isAnonymous'] ?? false,
      isTestimony: data['isTestimony'] ?? false,
    );
  }
}

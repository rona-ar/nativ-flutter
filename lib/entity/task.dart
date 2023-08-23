import 'package:nativ/config.dart';

class Task {
  final int id;
  final String title;
  final String pubYear;
  final String coverImage;
  final int progress;
  final int total;
  final bool done;

  Task(
      {required this.id,
      required this.title,
      required this.pubYear,
      required this.coverImage,
      required this.progress,
      required this.total,
      required this.done});

  factory Task.fromJson(Map<String, dynamic> json) {
    String networkImage = '';
    if (json['cover_image'] != '') {
      networkImage = '${CONFIG().DOMAIN_URL}/${json['cover_image']}';
    }
    return Task(
      id: json['id'],
      title: json['title'],
      pubYear: json['pub_year'],
      coverImage: networkImage,
      progress: json['progress'],
      total: json['total'],
      done: json['done'],
    );
  }
}

class Quote {
  final int id;
  final String sentence;
  final String? audioPath;
  final num pronunciation_score;
  final num accuracy_score;
  final num fluency_score;
  final num completeness_score;
  final List<ScoreDetail>? detail;
  final bool done;

  Quote({
    required this.id,
    required this.sentence,
    required this.audioPath,
    required this.pronunciation_score,
    required this.accuracy_score,
    required this.fluency_score,
    required this.completeness_score,
    this.detail,
    required this.done,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? detailJson = json['detail_score'];
    return Quote(
      id: json['id'],
      sentence: json['sentence'],
      audioPath: json['audio_path'],
      pronunciation_score: json['pronunciation_score'],
      accuracy_score: json['accuracy_score'],
      fluency_score: json['fluency_score'],
      completeness_score: json['completeness_score'],
      detail: detailJson != null && detailJson.isNotEmpty
          ? detailJson.map((item) => ScoreDetail.fromJson(item)).toList()
          : null,
      done: json['done'],
    );
  }
}

class ScoreDetail {
  final String word;
  final int accuracy;

  ScoreDetail({
    required this.word,
    required this.accuracy,
  });

  factory ScoreDetail.fromJson(Map<String, dynamic> json) {
    return ScoreDetail(
      word: json['word'],
      accuracy: json['accuracy'],
    );
  }
}

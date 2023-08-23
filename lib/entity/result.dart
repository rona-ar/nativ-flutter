import 'sentence.dart';

class ResultData {
  final num pronunciationScore;
  final num completenessScore;
  final num fluencyScore;
  final num accuracyScore;
  final List<ScoreDetail>? detail;

  ResultData({
    required this.pronunciationScore,
    required this.completenessScore,
    required this.fluencyScore,
    required this.accuracyScore,
    this.detail,
  });

  factory ResultData.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? detailJson = json['detail_score'];
    return ResultData(
      pronunciationScore: json['pronunciationScore'],
      completenessScore: json['completenessScore'],
      fluencyScore: json['fluencyScore'],
      accuracyScore: json['accuracyScore'],
      detail: detailJson != null && detailJson.isNotEmpty
          ? detailJson.map((item) => ScoreDetail.fromJson(item)).toList()
          : null,
    );
  }
}

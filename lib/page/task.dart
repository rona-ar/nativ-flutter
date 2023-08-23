import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nativ/config.dart';
import 'package:nativ/entity/sentence.dart';
import 'package:nativ/entity/task.dart';
import 'package:nativ/page/test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskPage extends StatefulWidget {
  final Task task;

  const TaskPage({super.key, required this.task});

  @override
  _TaskPageState createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task.title),
        backgroundColor: Colors.amber,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder(
                future: fetchData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(snapshot.error.toString()),
                    );
                  } else if (snapshot.hasData) {
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        var quote = snapshot.data![index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TestPage(
                                  quote: quote,
                                ),
                              ),
                            );
                          },
                          child: Card(
                            color: quote.done
                                ? Colors.lightGreen[100]
                                : Colors.white,
                            elevation: 2,
                            child: ListTile(
                              leading: const Icon(Icons.mic_rounded),
                              title: Text(quote.sentence),
                              trailing: Text(quote.done
                                  ? quote.pronunciation_score.toString()
                                  : ''),
                            ),
                          ),
                        );
                      },
                    );
                  }
                  return Container();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Quote>> fetchData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    int? userid = preferences.getInt('userid');
    final response = await http.get(Uri.parse(
        '${CONFIG().BASE_URL}/tugas/${widget.task.id}?id_mahasiswa=$userid')); // Ganti dengan URL API tugas Anda

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body) as List<dynamic>;
      List<Quote> sentences = jsonData.map((item) {
        return Quote(
          id: item['id'],
          sentence: item['sentence'],
          audioPath: item['audio_path'],
          pronunciation_score: item['pronunciation_score'],
          accuracy_score: item['accuracy_score'],
          fluency_score: item['fluency_score'],
          completeness_score: item['completeness_score'],
          detail: item['detail'] != null
              ? (json.decode(item['detail']) as List<dynamic>)
                  .map((detailItem) => ScoreDetail.fromJson(detailItem))
                  .toList()
              : null,
          done: item['done'],
        );
      }).toList();
      return sentences;
    } else {
      throw Exception('Failed to fetch data');
    }
  }
}

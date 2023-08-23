import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nativ/config.dart';
import 'package:nativ/entity/result.dart';
import 'package:nativ/entity/sentence.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestPage extends StatefulWidget {
  final Quote quote;
  const TestPage({super.key, required this.quote});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  String _recordPath = '';
  int _userId = 0;
  bool _isRecording = false;
  bool _isLoading = false;
  bool _hasRecorded = false;
  bool _hasResult = false;
  bool _hasError = false;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;
  PlayerState _audioPlayerState = PlayerState.stopped;
  PlayerState _audioSentencePlayerState = PlayerState.stopped;
  final AudioPlayer _recorderPlayer = AudioPlayer();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final record = Record();
  ResultData _result = ResultData(
      pronunciationScore: 0,
      completenessScore: 0,
      fluencyScore: 0,
      accuracyScore: 0,
      detail: null);

  @override
  void initState() {
    _isRecording = false;
    _isRecording = false;
    _hasRecorded = false;
    _hasResult = widget.quote.done;
    _hasError = false;
    if (widget.quote.done) {
      ResultData result = ResultData(
          pronunciationScore: widget.quote.pronunciation_score,
          completenessScore: widget.quote.completeness_score,
          fluencyScore: widget.quote.fluency_score,
          accuracyScore: widget.quote.accuracy_score,
          detail: widget.quote.detail);
      _result = result;
    }
    initUser();
    super.initState();
  }

  Future<void> initUser() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    int? userid = preferences.getInt('userid');

    setState(() {
      _userId = userid!;
    });
  }

  @override
  void dispose() {
    record.dispose();
    _audioPlayer.dispose();
    _recorderPlayer.dispose();
    super.dispose();
  }

  Future<String> _generateFileName() async {
    final externalDir = await getExternalStorageDirectory();
    final now = DateTime.now().millisecondsSinceEpoch;
    return '${externalDir!.path}/$now.wav';
  }

  Future<void> _start() async {
    String filename = await _generateFileName();
    bool hasPermission = await record.hasPermission();
    if (hasPermission) {
      await record.start(
        path: filename,
        encoder: AudioEncoder.wav,
      );
    }
    bool isRecording = await record.isRecording();
    print("TAG is_recording $isRecording");
    setState(() {
      _isRecording = isRecording;
      _recordPath = filename;
    });
  }

  Future _stop() async {
    await record.stop();
    setState(() {
      _isRecording = false;
      _hasRecorded = true;
    });
  }

  Future<void> _playAudioSentence() async {
    String path = "${CONFIG().DOMAIN_URL}/${widget.quote.audioPath}";
    await _audioPlayer.play(UrlSource(path));
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      setState(() {
        _audioSentencePlayerState = state;
      });
    });
  }

  Future<void> _playRecording() async {
    _recorderPlayer.onPlayerStateChanged.listen((PlayerState state) {
      setState(() {
        _audioPlayerState = state;
      });
    });
    _recorderPlayer.onDurationChanged.listen((Duration duration) {
      setState(() {
        _audioDuration = duration;
      });
    });
    _recorderPlayer.onPositionChanged.listen((Duration position) {
      setState(() {
        _audioPosition = position;
      });
    });
    if (_audioPlayerState == PlayerState.stopped) {
      await _recorderPlayer.play(DeviceFileSource(_recordPath));
    } else {
      await _recorderPlayer.resume();
    }
  }

  Future<void> _pauseRecording() async {
    await _recorderPlayer.pause();
    setState(() {
      _audioPlayerState = PlayerState.paused;
    });
  }

  Future<void> _storeResult(responseBody) async {
    print("TAG START STORE RESULT");
    String url = "${CONFIG().BASE_URL}/speech-recognition";
    var request = http.MultipartRequest('POST', Uri.parse(url));

    request.fields['reference_text'] = widget.quote.sentence;
    request.fields['id_mahasiswa'] = _userId.toString();
    request.fields['id_quote'] = widget.quote.id.toString();
    request.fields['data'] = responseBody;
    request.files.add(await http.MultipartFile.fromPath('audio', _recordPath));

    final nres = await request.send();
    if (nres.statusCode == 200) {
      var responseBody = await nres.stream.bytesToString();
      var data = json.decode(responseBody);
      var detail = data['detail'] != null
          ? (data['detail'] as List<dynamic>)
              .map((detailItem) => ScoreDetail.fromJson(detailItem))
              .toList()
          : null;
      ResultData result = ResultData(
        pronunciationScore: data['pronunciation_score'],
        completenessScore: data['completeness_score'],
        fluencyScore: data['fluency_score'],
        accuracyScore: data['accuracy_score'],
        detail: detail,
      );
      setState(() {
        _hasResult = true;
        _result = result;
      });
    } else {
      setState(() {
        _hasError = true;
      });
    }
  }

  Future<void> _sendForResult() async {
    print("TAG START SEND FOR RESULT");
    setState(() {
      _isLoading = true;
    });
    String url = CONFIG().ASR_URL;

    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.fields['reference_text'] = widget.quote.sentence;
    request.files.add(await http.MultipartFile.fromPath('audio', _recordPath));

    var res = await request.send();
    print(res.statusCode);

    if (res.statusCode == 200) {
      final responseBody = await res.stream.bytesToString();
      await _storeResult(responseBody);
    } else {
      setState(() {
        _hasError = true;
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pronunciation Test"),
        backgroundColor: Colors.amber,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton:
          _hasResult == true || _audioSentencePlayerState == PlayerState.playing
              ? Container()
              : FloatingActionButton(
                  onPressed: () {
                    if (_isRecording) {
                      _stop();
                    } else {
                      _start();
                    }
                  },
                  backgroundColor: _isRecording ? Colors.red : Colors.blue,
                  child: Icon(_isRecording ? Icons.stop : Icons.mic),
                ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildQuestionBlock(),
              const SizedBox(
                height: 20,
              ),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _hasError
                      ? const Center(child: Text("Gagal Melakukan Request"))
                      : _hasResult
                          ? Result()
                          : _hasRecorded
                              ? Recorded()
                              : Container(),
            ],
          ),
        ),
      ),
    );
  }

  Stack _buildQuestionBlock() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 18),
          child: Card(
            elevation: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    widget.quote.sentence,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(
                  height: 36,
                )
              ],
            ),
          ),
        ),
        Visibility(
          visible: widget.quote.audioPath != null,
          child: Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: _isRecording ? null : _playAudioSentence,
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.green,
                ),
                child: const Icon(
                  Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget Recorded() {
    return Column(
      children: [
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Material(
                  elevation: 1,
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.grey[300],
                  child: IconButton(
                    icon: Icon(_audioPlayerState == PlayerState.playing
                        ? Icons.pause
                        : Icons.play_arrow),
                    onPressed: () {
                      if (_audioPlayerState == PlayerState.playing) {
                        _pauseRecording();
                      } else {
                        _playRecording();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: LinearProgressIndicator(
                    value: _audioDuration.inMilliseconds > 0
                        ? _audioPosition.inMilliseconds /
                            _audioDuration.inMilliseconds
                        : 0.0, // Ubah sesuai dengan posisi buffering
                    backgroundColor: Colors.grey,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        ElevatedButton(
          onPressed: _sendForResult,
          child: const Text("Submit"),
        )
      ],
    );
  }

  Widget Result() {
    return Column(
      children: [
        Card(
          elevation: 2,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                const Text(
                  "Pronunciation Score",
                  style: TextStyle(fontSize: 24),
                ),
                Text(
                  _result.pronunciationScore.toString(),
                  style: const TextStyle(
                      fontSize: 50, fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 20,
                ),
                IntrinsicHeight(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          color: Colors.yellow,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Accuracy",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(_result.accuracyScore.toString()),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          color: Colors.blue,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Fluency",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(_result.fluencyScore.toString()),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          color: Colors.green,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Completeness",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(_result.completenessScore.toString()),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        Card(
          child: Container(
            padding: const EdgeInsets.all(8.0),
            width: double.infinity,
            child: const Column(
              children: [
                Text(
                  "Pronunciation Detail",
                  style: TextStyle(fontSize: 24),
                ),
              ],
            ),
          ),
        ),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _result.detail?.length ?? 0,
          itemBuilder: (context, index) {
            final detail = _result.detail![index];
            Color progressColor = Colors.green;
            if (detail.accuracy < 50) {
              progressColor = Colors.red;
            } else if (detail.accuracy < 75) {
              progressColor = Colors.orange;
            }
            return Card(
              elevation: 2,
              child: ListTile(
                title: Text(
                  detail.word,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: progressColor),
                ),
                trailing: SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: detail.accuracy / 100,
                        semanticsValue: detail.accuracy.toString(),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                      Center(
                        child: Text(
                          "${detail.accuracy}%",
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

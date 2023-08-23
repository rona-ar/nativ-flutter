import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nativ/component/user-info.dart';
import 'package:nativ/config.dart';
import 'package:nativ/entity/task.dart';
import 'package:nativ/page/task.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _name = '';
  List<Task> _tasks = [];
  Future<List<Task>>? _taskListFuture;

  @override
  void initState() {
    fetchUser();
    super.initState();
  }

  Future fetchUser() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String? username = preferences.getString('username');
    setState(() {
      _name = username!;
      _taskListFuture = fetchTasks();
    });
  }

  Future<List<Task>> fetchTasks() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    int? userid = preferences.getInt('userid');
    final response = await http
        .get(Uri.parse('${CONFIG().BASE_URL}/tugas?id_mahasiswa=$userid'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _tasks = List<Task>.from(data.map((task) => Task.fromJson(task)));
      });
    }
    return _tasks;
  }

  int _selectedTabIndex = 0;

  List<Task> _currentTasks() {
    if (_selectedTabIndex == 0) {
      return _tasks.where((task) => !task.done).toList();
    } else {
      return _tasks.where((task) => task.done).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          UserInfo(
            username: _name,
          ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedTabIndex = 0;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedTabIndex == 0
                        ? Colors.amber[600]
                        : Colors.white24,
                  ),
                  child: const Text('New'),
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedTabIndex = 1;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedTabIndex == 1
                        ? Colors.amber[600]
                        : Colors.white24,
                  ),
                  child: const Text('History'),
                ),
              ),
            ],
          ),
          Expanded(
            child: FutureBuilder(
              future: _taskListFuture,
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
                  final taskList = _currentTasks();
                  return ListView.builder(
                    itemCount: taskList.length,
                    itemBuilder: (context, index) {
                      final task = taskList[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskPage(task: task),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 4,
                          child: _buildItem(task, context),
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
    );
  }

  Widget _buildItem(Task task, BuildContext context) {
    var percentage = task.progress / task.total;
    return Column(
      children: [
        LinearProgressIndicator(
          value: percentage,
        ),
        IntrinsicHeight(
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: task.coverImage != ''
                    ? Image.network(
                        task.coverImage,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: DefaultTextStyle.of(context).style,
                              children: [
                                TextSpan(
                                  text: task.pubYear,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            TextSpan(
                              text: '${task.progress}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(
                              text: ' out of ',
                            ),
                            TextSpan(
                              text: '${task.total}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(
                              text: ' completed',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Stack _buildTaskItem(Task task, BuildContext context) {
    return Stack(
      children: [
        task.coverImage != ''
            ? Image.network(
                task.coverImage,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            : Container(),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              LinearProgressIndicator(
                value: task.progress / task.total,
              ),
              Container(
                color: const Color.fromARGB(225, 255, 255, 255),
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            TextSpan(
                              text: '${task.progress}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(
                              text: ' out of ',
                            ),
                            TextSpan(
                              text: '${task.total}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(
                              text: ' completed',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

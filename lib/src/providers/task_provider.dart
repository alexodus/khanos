import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:khanos/src/models/task_model.dart';
import 'package:khanos/src/preferences/user_preferences.dart';
import 'package:khanos/src/utils/utils.dart';

class TaskProvider {
  final _prefs = new UserPreferences();

  Future<List<TaskModel>> getTasks(int projectId, int statusId) async {
    final Map<String, dynamic> parameters = {
      "jsonrpc": "2.0",
      "method": "getAllTasks",
      "id": 1,
      "params": {"project_id": projectId, "status_id": statusId}
    };

    final credentials = "${_prefs.username}:${_prefs.password}";

    Codec<String, String> stringToBase64 = utf8.fuse(base64);

    String encoded = stringToBase64.encode(credentials);

    final resp = await http.post(
      Uri.parse(_prefs.endpoint),
      headers: <String, String>{"Authorization": "Basic $encoded"},
      body: json.encode(parameters),
      encoding: Encoding.getByName("utf-8"),
    );

    final decodedData = json.decode(utf8.decode(resp.bodyBytes));

    final List<TaskModel> tasks = [];

    final List<dynamic> results = decodedData['result'];

    if (decodedData == null) return [];

    // Check for errors
    if (decodedData['error'] != null) {
      return Future.error(decodedData['error']);
    }

    results.forEach((task) {
      final taskTemp = TaskModel.fromJson(task);
      tasks.add(taskTemp);
    });
    return tasks;
  }

  Future<int> createTask(Map<String, dynamic> args) async {
    final Map<String, dynamic> parameters = {
      "jsonrpc": "2.0",
      "method": "createTask",
      "id": 1176509098,
      "params": args
    };
    print(parameters);
    final credentials = "${_prefs.username}:${_prefs.password}";

    Codec<String, String> stringToBase64 = utf8.fuse(base64);

    String encoded = stringToBase64.encode(credentials);

    final resp = await http.post(
      Uri.parse(_prefs.endpoint),
      headers: <String, String>{"Authorization": "Basic $encoded"},
      body: json.encode(parameters),
      encoding: Encoding.getByName("utf-8"),
    );

    final decodedData = json.decode(utf8.decode(resp.bodyBytes));
    print(decodedData);
    final result = decodedData['result'];

    if (decodedData == null) return 0;

    return (result != false) ? result : 0;
  }

  Future<bool> updateTask(Map<String, dynamic> args) async {
    final Map<String, dynamic> parameters = {
      "jsonrpc": "2.0",
      "method": "updateTask",
      "id": 1406803059,
      "params": args
    };

    print(parameters);

    final credentials = "${_prefs.username}:${_prefs.password}";

    Codec<String, String> stringToBase64 = utf8.fuse(base64);

    String encoded = stringToBase64.encode(credentials);

    final resp = await http.post(
      Uri.parse(_prefs.endpoint),
      headers: <String, String>{"Authorization": "Basic $encoded"},
      body: json.encode(parameters),
      encoding: Encoding.getByName("utf-8"),
    );

    final decodedData = json.decode(utf8.decode(resp.bodyBytes));

    print(decodedData);

    final result = decodedData['result'];

    if (decodedData == null) return false;

    return result;
  }

  Future<bool> removeTask(int taskId) async {
    final Map<String, dynamic> parameters = {
      "jsonrpc": "2.0",
      "method": "removeTask",
      "id": 1423501287,
      "params": {"task_id": taskId}
    };

    print(parameters);

    final credentials = "${_prefs.username}:${_prefs.password}";

    Codec<String, String> stringToBase64 = utf8.fuse(base64);

    String encoded = stringToBase64.encode(credentials);

    final resp = await http.post(
      Uri.parse(_prefs.endpoint),
      headers: <String, String>{"Authorization": "Basic $encoded"},
      body: json.encode(parameters),
      encoding: Encoding.getByName("utf-8"),
    );

    final decodedData = json.decode(utf8.decode(resp.bodyBytes));

    print(decodedData);

    final result = decodedData['result'];

    if (decodedData == null) return false;

    return result;
  }
}

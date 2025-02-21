import 'dart:async';

import 'package:flutter/material.dart';
import 'package:khanos/src/models/column_model.dart';
import 'package:khanos/src/models/project_model.dart';
import 'package:khanos/src/models/swimlane_model.dart';
import 'package:khanos/src/models/tag_model.dart';
import 'package:khanos/src/models/task_model.dart';
import 'package:khanos/src/models/user_model.dart';
import 'package:khanos/src/preferences/user_preferences.dart';
import 'package:khanos/src/providers/column_provider.dart';
import 'package:khanos/src/providers/project_provider.dart';
import 'package:khanos/src/providers/subtask_provider.dart';
import 'package:khanos/src/providers/swimlane_provider.dart';
import 'package:khanos/src/providers/tag_provider.dart';
import 'package:khanos/src/providers/task_provider.dart';
import 'package:khanos/src/providers/user_provider.dart';
import 'package:khanos/src/utils/datetime_utils.dart';
import 'package:khanos/src/utils/utils.dart';
import 'package:khanos/src/utils/widgets_utils.dart';
import 'package:khanos/src/utils/theme_utils.dart';
import 'package:shimmer/shimmer.dart';

class TaskPage extends StatefulWidget {
  @override
  _TaskPageState createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final _prefs = new UserPreferences();
  Map<String, dynamic> error;
  TaskModel task = new TaskModel();
  int taskId;
  List<ColumnModel> projectColumns = [];
  List<TagModel> _tags = [];
  List<SwimlaneModel> swimlanes = [];
  ProjectModel project;
  String userRole;
  final taskProvider = new TaskProvider();
  final tagProvider = new TagProvider();
  final subtaskProvider = new SubtaskProvider();
  final userProvider = new UserProvider();
  final columnProvider = new ColumnProvider();

  bool _darkTheme;
  ThemeData currentThemeData;

  @override
  void initState() {
    _darkTheme = _prefs.darkTheme;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    currentThemeData =
        _darkTheme == true ? ThemeData.dark() : ThemeData.light();
    final Map taskArgs = ModalRoute.of(context).settings.arguments;

    // final String projectName = taskArgs['project_name'];
    project = taskArgs['project'];
    userRole = taskArgs['userRole'];
    taskId = int.parse(taskArgs['task_id']);

    return Scaffold(
      appBar: normalAppBar(project.name),
      body: Container(width: double.infinity, child: _taskInfo()),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            backgroundColor: Colors.blue,
            heroTag: "subtaskListHero",
            onPressed: () {
              Navigator.pushNamed(context, 'subtask',
                      arguments: {'task': task, 'userRole': userRole})
                  .then((_) => setState(() {}));
            },
            child: Icon(Icons.playlist_add_check_rounded),
          ),
          SizedBox(width: 10.0),
          FloatingActionButton(
            backgroundColor: Colors.blue,
            heroTag: "commentsHero",
            onPressed: () {
              Navigator.pushNamed(context, 'comment',
                      arguments: {'task': task, 'userRole': userRole})
                  .then((_) => setState(() {}));
            },
            child: Icon(Icons.comment),
          ),
          SizedBox(width: 10.0),
          (userRole != 'project-viewer')
              ? FloatingActionButton(
                  backgroundColor: Colors.blue,
                  heroTag: "editTaskHero",
                  onPressed: () async {
                    Navigator.pushNamed(context, 'taskForm', arguments: {
                      'task': task,
                      'project': project,
                      'tags': _tags,
                    }).then((_) => setState(() {}));
                  },
                  child: Icon(Icons.edit),
                )
              : SizedBox(),
        ],
      ),
    );
  }

  _taskInfo() {
    return FutureBuilder(
      future: Future.wait([
        TaskProvider().getTask(taskId),
        ProjectProvider().getProjectUsers(int.parse(project.id)),
        SwimlaneProvider().getActiveSwimlanes(int.parse(project.id)),
      ]),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasError) {
          processApiError(snapshot.error);
          error = snapshot.error;
          if (_prefs.authFlag != true) {
            final SnackBar _snackBar = SnackBar(
              content: const Text('Login Failed!'),
              duration: const Duration(seconds: 5),
            );
            @override
            void run() {
              scheduleMicrotask(() {
                ScaffoldMessenger.of(context).showSnackBar(_snackBar);
                Navigator.pushReplacementNamed(context, 'login',
                    arguments: {'error': snapshot.error});
              });
            }

            run();
          } else {
            return Container(
                width: double.infinity,
                padding: EdgeInsets.only(top: 20.0),
                child: errorPage(snapshot.error));
          }
        }

        if (snapshot.hasData) {
          task = snapshot.data[0];
          List<UserModel> projectUsers = snapshot.data[1];
          swimlanes = snapshot.data[2];
          SwimlaneModel swimlane =
              swimlanes.firstWhere((element) => element.id == task.swimlaneId);
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(
                      top: 20.0, left: 20.0, right: 20.0, bottom: 40.0),
                  children: [
                    Row(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width / 1.2,
                          child: Text('Task #${task.id} - ${task.title}',
                              style: TextStyle(
                                  fontSize: 22, fontStyle: FontStyle.normal)),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.0),
                    (userRole != 'project-viewer')
                        ? _closeTaskButton()
                        : Container(),
                    SizedBox(height: 20.0),
                    Row(children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: Icon(Icons.calendar_today_outlined,
                            color: Colors.blueGrey),
                      ),
                      Text(
                          'Created: ${getStringDateTimeFromEpoch("dd/MM/yy - HH:mm", task.dateCreation)}'),
                    ]),
                    SizedBox(height: 20.0),
                    Row(children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child:
                            Icon(Icons.calendar_today, color: Colors.blueGrey),
                      ),
                      Text(
                          'Modified: ${getStringDateTimeFromEpoch("dd/MM/yy - HH:mm", task.dateModification)}'),
                    ]),
                    SizedBox(height: 20.0),
                    Row(children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: Icon(Icons.security_rounded,
                            color: Colors.blueGrey),
                      ),
                      (task.creatorId != '0')
                          ? _userButton(projectUsers
                              .firstWhere(
                                  (element) => element.id == task.creatorId)
                              .name)
                          : Text('N/A'),
                    ]),
                    SizedBox(height: 20.0),
                    Row(children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: Icon(Icons.person, color: Colors.blueGrey),
                      ),
                      (task.ownerId != '0')
                          ? _userButton(projectUsers
                              .firstWhere(
                                  (element) => element.id == task.ownerId)
                              .name)
                          : Text('N/A'),
                    ]),

                    SizedBox(height: 20.0),
                    Row(children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: Icon(Icons.table_rows_rounded,
                            color: Colors.blueGrey),
                      ),
                      Text('Swimlane: ${swimlane.name}'),
                    ]),

                    SizedBox(height: 20.0),
                    Row(children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: Icon(Icons.watch_later_outlined,
                            color: Colors.blueGrey),
                      ),
                      Text('Estimated: ${task.timeEstimated} hours')
                    ]),
                    SizedBox(height: 20.0),
                    Row(children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: Icon(Icons.watch_later_outlined,
                            color: Colors.blueGrey),
                      ),
                      Text('Spent: ${task.timeSpent} hours')
                    ]),
                    SizedBox(height: 20.0),
                    task.dateStarted != '0'
                        ? Row(children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child: Icon(Icons.calendar_today,
                                  color: Colors.blueGrey),
                            ),
                            Text(
                                'Start: ${getStringDateTimeFromEpoch("dd/MM/yy - HH:mm", task.dateStarted)}'),
                          ])
                        : Container(),
                    SizedBox(height: 20.0),
                    task.dateDue != '0'
                        ? Row(children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child: Icon(Icons.calendar_today,
                                  color: Colors.blueGrey),
                            ),
                            Text(
                                'Modified: ${getStringDateTimeFromEpoch("dd/MM/yy - HH:mm", task.dateDue)}'),
                          ])
                        : Container(),
                    Row(
                      children: [
                        Text('Tags',
                            style: TextStyle(fontSize: 20.0),
                            textAlign: TextAlign.left),
                      ],
                    ),
                    SizedBox(height: 10.0),
                    _taskTags(task.id),
                    Row(
                      children: [
                        Text('Description',
                            style: TextStyle(fontSize: 20.0),
                            textAlign: TextAlign.left),
                      ],
                    ),
                    SizedBox(height: 10.0),
                    Card(
                        elevation: 3.0,
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Text(
                              task.description != ""
                                  ? task.description
                                  : 'No Description',
                              textAlign: TextAlign.left),
                        )),
                    SizedBox(height: 20.0),
                    // Text('Sub-tasks', style: TextStyle(fontSize: 20.0)),
                  ],
                ),
              ),
            ],
          );
        } else {
          return _shimmerPage();
        }
      },
    );
  }

  Widget _getUserFullName(String creatorId) {
    return FutureBuilder(
        future: UserProvider().getUser(int.parse(creatorId)),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasError) {
            processApiError(snapshot.error);
            error = snapshot.error;
            if (_prefs.authFlag != true) {
              final SnackBar _snackBar = SnackBar(
                content: const Text('Login Failed!'),
                duration: const Duration(seconds: 5),
              );
              @override
              void run() {
                scheduleMicrotask(() {
                  ScaffoldMessenger.of(context).showSnackBar(_snackBar);
                  Navigator.pushReplacementNamed(context, 'login',
                      arguments: {'error': snapshot.error});
                });
              }

              run();
            }
          }
          if (snapshot.hasData) {
            final UserModel user = snapshot.data;
            return _userButton(user.username);
          } else {
            return Text('Loading..');
          }
        });
  }

  void _closeTask(String taskId) async {
    bool result = await taskProvider.closeTask(int.parse(taskId));
    Navigator.pop(context);
    if (result) {
      setState(() {
        Navigator.pop(context);
      });
    } else {
      mostrarAlerta(context, 'Something went Wront!');
    }
  }

  Widget _closeTaskButton() {
    return GestureDetector(
      onTap: () {
        showLoaderDialog(context);
        Feedback.forTap(context);
        _closeTask(task.id);
      },
      child: Container(
        margin: EdgeInsets.only(right: 10),
        alignment: Alignment.center,
        child: Text(
          'Close Task',
          style: TextStyle(color: Colors.white),
        ),
        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(5),
          ),
          color: CustomColors.TrashRed,
          boxShadow: [
            BoxShadow(
              color: CustomColors.TrashRed,
              blurRadius: 4.0,
              spreadRadius: 1.0,
              offset: Offset(0.0, 0.0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _userButton(String name) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: EdgeInsets.only(right: 10),
        child: Text(
          name,
          style: TextStyle(color: Colors.white),
        ),
        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(5),
          ),
          color: CustomColors.BlueShadow,
          boxShadow: [
            BoxShadow(
              color: CustomColors.BlueDark,
              blurRadius: 4.0,
              spreadRadius: 1.0,
              offset: Offset(0.0, 0.0),
            ),
          ],
        ),
      ),
    );
  }

  _taskTags(String taskId) {
    return FutureBuilder(
        future: TagProvider().getTagsByTask(int.parse(taskId)),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasError) {
            processApiError(snapshot.error);
            error = snapshot.error;
            if (_prefs.authFlag != true) {
              final SnackBar _snackBar = SnackBar(
                content: const Text('Login Failed!'),
                duration: const Duration(seconds: 5),
              );
              @override
              void run() {
                scheduleMicrotask(() {
                  ScaffoldMessenger.of(context).showSnackBar(_snackBar);
                  Navigator.pushReplacementNamed(context, 'login',
                      arguments: {'error': snapshot.error});
                });
              }

              run();
            }
          }
          if (snapshot.hasData) {
            _tags = snapshot.data;
            if (_tags.length > 0) {
              List<Widget> chips = [];
              _tags.forEach((tag) {
                chips.add(Chip(
                  backgroundColor: Colors.blue,
                  elevation: 4.0,
                  label: Text(
                    tag.name,
                  ),
                ));
              });
              return Wrap(spacing: 5.0, children: chips);
            } else {
              return Text('No Tags');
            }
          } else {
            return Text('Loading...');
          }
        });
  }

  _shimmerPage() {
    return Shimmer.fromColors(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(
                  top: 20.0, left: 20.0, right: 20.0, bottom: 40.0),
              children: [
                Row(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width / 1.2,
                      child: Text('Task #...',
                          style: TextStyle(
                              fontSize: 22, fontStyle: FontStyle.normal)),
                    ),
                  ],
                ),
                SizedBox(height: 20.0),
                Container(
                  margin: EdgeInsets.only(right: 10),
                  alignment: Alignment.center,
                  child: Text(
                    'Close Task',
                    style: TextStyle(color: Colors.white),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(5),
                    ),
                    color: CustomColors.TrashRed,
                    boxShadow: [
                      BoxShadow(
                        color: CustomColors.TrashRed,
                        blurRadius: 4.0,
                        spreadRadius: 1.0,
                        offset: Offset(0.0, 0.0),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.0),
                Row(children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: Icon(Icons.calendar_today_outlined,
                        color: Colors.blueGrey),
                  ),
                  Text('Created: dd/MM/yy - HH:mm'),
                ]),
                SizedBox(height: 20.0),
                Row(children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: Icon(Icons.calendar_today, color: Colors.blueGrey),
                  ),
                  Text('Modified: dd/MM/yy - HH:mm'),
                ]),
                SizedBox(height: 20.0),
                Row(children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: Icon(Icons.person, color: Colors.blueGrey),
                  ),
                  Container(
                    margin: EdgeInsets.only(right: 10),
                    child: Text(
                      'John Doe...',
                      style: TextStyle(color: Colors.white),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(
                        Radius.circular(5),
                      ),
                      color: CustomColors.BlueShadow,
                      boxShadow: [
                        BoxShadow(
                          color: CustomColors.GreenShadow,
                          blurRadius: 5.0,
                          spreadRadius: 3.0,
                          offset: Offset(0.0, 0.0),
                        ),
                      ],
                    ),
                  ),
                ]),
                SizedBox(height: 20.0),
                Row(children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: Icon(Icons.watch_later_outlined,
                        color: Colors.blueGrey),
                  ),
                  Text('Estimated: some hours')
                ]),
                SizedBox(height: 20.0),
                Row(children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: Icon(Icons.watch_later_outlined,
                        color: Colors.blueGrey),
                  ),
                  Text('Spent: some hours')
                ]),
                SizedBox(height: 20.0),
                Row(
                  children: [
                    Text('Tags',
                        style: TextStyle(fontSize: 20.0),
                        textAlign: TextAlign.left),
                  ],
                ),
                SizedBox(height: 10.0),
                // _taskTags(task.id),
                Row(
                  children: [
                    Text('Description',
                        style: TextStyle(fontSize: 20.0),
                        textAlign: TextAlign.left),
                  ],
                ),
                SizedBox(height: 10.0),
                Card(
                    elevation: 3.0,
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Text('A quick brown fox jumped over...',
                          textAlign: TextAlign.left),
                    )),
                SizedBox(height: 20.0),
              ],
            ),
          ),
        ],
      ),
      baseColor: CustomColors.BlueDark,
      highlightColor: Colors.lightBlue[200],
    );
  }
}

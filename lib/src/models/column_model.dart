// To parse this JSON data, do
//
//     final columnModel = columnModelFromJson(jsonString);

import 'dart:convert';

ColumnModel columnModelFromJson(String str) =>
    ColumnModel.fromJson(json.decode(str));

String columnModelToJson(ColumnModel data) => json.encode(data.toJson());

class ColumnModel {
  ColumnModel({
    this.id,
    this.title,
    this.position,
    this.projectId,
    this.taskLimit,
  });

  String id;
  String title;
  String position;
  String projectId;
  String taskLimit;

  factory ColumnModel.fromJson(Map<String, dynamic> json) => ColumnModel(
        id: json["id"].toString(),
        title: json["title"],
        position: json["position"].toString(),
        projectId: json["project_id"].toString(),
        taskLimit: json["task_limit"].toString(),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "position": position,
        "project_id": projectId,
        "task_limit": taskLimit,
      };
}

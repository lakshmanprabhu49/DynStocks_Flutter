// To parse this JSON data, do
//
//     final errorClass = errorClassFromJson(jsonString);

import 'dart:convert';

ErrorClass errorClassFromJson(String str) =>
    ErrorClass.fromJson(json.decode(str));

String errorClassToJson(ErrorClass data) => json.encode(data.toJson());

class ErrorClass {
  ErrorClass({
    required this.message,
  });

  String message;

  factory ErrorClass.fromJson(Map<String, dynamic> json) => ErrorClass(
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "message": message,
      };
}

// To parse this JSON data, do
//
//     final authResponse = authResponseFromJson(jsonString);

import 'dart:convert';

AuthResponse authResponseFromJson(String str) =>
    AuthResponse.fromJson(json.decode(str));

String authResponseToJson(AuthResponse data) => json.encode(data.toJson());

class AuthResponse {
  AuthResponse({
    required this.message,
    required this.userId,
  });

  String message;
  String userId;

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        message: json["message"],
        userId: json["userId"],
      );

  Map<String, dynamic> toJson() => {
        "message": message,
        "userId": userId,
      };
}

AuthBody authBodyFromJson(String str) => AuthBody.fromJson(json.decode(str));

String authBodyToJson(AuthBody data) => json.encode(data.toJson());

class AuthBody {
  AuthBody({
    required this.username,
    required this.password,
  });

  String username;
  String password;

  factory AuthBody.fromJson(Map<String, dynamic> json) => AuthBody(
        username: json["username"],
        password: json["password"],
      );

  Map<String, dynamic> toJson() => {
        "username": username,
        "password": password,
      };
}

// To parse this JSON data, do
//
//     final localUserCreds = localUserCredsFromJson(jsonString);

import 'dart:convert';

LocalUserCreds localUserCredsFromJson(String str) =>
    LocalUserCreds.fromJson(json.decode(str));

String localUserCredsToJson(LocalUserCreds data) => json.encode(data.toJson());

class LocalUserCreds {
  LocalUserCreds({
    required this.userId,
    required this.accessCode,
  });

  String userId;
  String accessCode;

  factory LocalUserCreds.fromJson(Map<String, dynamic> json) => LocalUserCreds(
        userId: json["userId"],
        accessCode: json["accessCode"],
      );

  Map<String, dynamic> toJson() => {
        "userId": userId,
        "accessCode": accessCode,
      };
}

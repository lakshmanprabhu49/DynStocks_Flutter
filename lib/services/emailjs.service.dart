import 'dart:io';

import 'package:dynstocks/models/email.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailJSService {
  Future<void> sendEmail(Email email) async {
    String serviceId = dotenv.env["EMAILJS_SERVICE_ID"] as String;
    String templateId = dotenv.env["EMAILJS_TEMPLATE_ID"] as String;
    String userId = dotenv.env["EMAILJS_USER_ID"] as String;
    final url = Uri.parse(dotenv.env["EMAILJS_API_ENDPOINT"] as String);
    var client = http.Client();
    var response = await client.post(url,
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': userId,
          'template_params': {
            'username': email.username,
            'subject': email.subject,
            'title': email.title,
            'subtitle': email.subtitle,
            'body': email.body,
          }
        }),
        headers: {
          'origin': 'http://localhost',
          HttpHeaders.contentTypeHeader: 'application/json',
        });
    print(response.statusCode);
  }
}

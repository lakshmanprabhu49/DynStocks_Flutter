import 'dart:convert';

import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/error_class.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class GmailErrorMessageService {
  static final GoogleSignIn _googleSignIn =
      GoogleSignIn(scopes: ['https://mail.google.com/']);

  static Future<GoogleSignInAccount?> signIntoGoogle() async {
    bool isUserSignedIn = await _googleSignIn.isSignedIn();
    if (isUserSignedIn) {
      return _googleSignIn.currentUser;
    }
    return await _googleSignIn.signIn();
  }

  static Future<void> sendEmail(String subject, String html) async {
    GoogleSignInAccount user = await signIntoGoogle() as GoogleSignInAccount;
    final auth = await user.authentication;
    final accessToken = auth.accessToken as String;
    Message message = Message();
    message.from = user.email;
    message.recipients = [user.email];
    message.subject = subject;
    message.html = html;
    SmtpServer smtpServer = gmailSaslXoauth2(user.email, accessToken);
    try {
      await send(message, smtpServer);
    } on MailerException catch (error) {
      print(error.message);
      throw Exception(error.message);
    }
  }
}

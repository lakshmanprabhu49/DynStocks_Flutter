import 'dart:convert';

import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/error_class.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class GmailErrorMessageService {
  GoogleSignIn _googleSignIn =
      GoogleSignIn(scopes: ['https://mail.google.com/']);

  Future<GoogleSignInAccount?> signIntoGoogle() async {
    if (await _googleSignIn.isSignedIn()) {
      return _googleSignIn.currentUser;
    }
    return await _googleSignIn.signIn();
  }

  Future<void> sendEmail(String subject, String text) async {
    GoogleSignInAccount user = await signIntoGoogle() as GoogleSignInAccount;
    final auth = await user.authentication;
    final accessToken = auth.accessToken as String;
    Message message = Message();
    message.from = user.email;
    message.recipients = [user.email];
    message.subject = subject;
    message.text = text;
    SmtpServer smtpServer = gmailSaslXoauth2(user.email, accessToken);
    try {
      await send(message, smtpServer);
    } on MailerException catch (error) {
      throw Exception(error.message);
    }
  }
}

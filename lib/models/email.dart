class Email {
  String username;
  String subject;
  String title;
  String subtitle;
  String body;

  Email(
      {required this.username,
      required this.subject,
      required this.title,
      required this.subtitle,
      required this.body});

  factory Email.fromJson(Map<String, dynamic> json) => Email(
      username: json["username"],
      subject: json["subject"],
      title: json["title"],
      subtitle: json["subtitle"],
      body: json["body"]);

  Map<String, dynamic> toJson() => {
        "username": username,
        "subject": subject,
        "title": title,
        "subtitle": subtitle,
        "body": body,
      };
}

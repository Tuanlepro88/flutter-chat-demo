import 'package:flutter_chat_demo/constants/constants.dart';

class MessageChat {
  int pk;
  String text;
  String created;
  String modified;
  String sender;
  String recipient;
  bool out;
  bool read;

  MessageChat({
    required this.pk,
    required this.text,
    required this.created,
    required this.modified,
    required this.sender,
    required this.recipient,
    required this.out,
    required this.read,
  });


  factory MessageChat.fromJson(json) {
    return MessageChat(
      pk: json["pk"], 
      text: json["text"], 
      created: json["created"], 
      modified: json["modified"], 
      sender: "${json["sender"]["pk"] ?? ""}", 
      recipient: "${json["recipient"]["pk"] ?? ""}", 
      out: json["out"], 
      read: json["read"], 
    );
  }

  
}

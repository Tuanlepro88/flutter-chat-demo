import 'package:flutter_chat_demo/constants/constants.dart';

class UserChat {
  String id;
  String photoUrl;
  String nickname;
  String lastMessage;
  int unread;

  UserChat({required this.id, required this.photoUrl, required this.nickname, required this.lastMessage, required this.unread});
  
}

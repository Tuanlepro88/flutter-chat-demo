import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:flutter_chat_demo/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:dio/dio.dart';

class ChatProvider extends ChangeNotifier{
  final SharedPreferences prefs;
  WebSocketChannel? _channel;
  late Map<String, List<MessageChat>> chatMessages = new Map();
  bool isLoading = false;
  String userId = "";
  String userName = "";

  ChatProvider({required this.prefs});

  String? getPref(String key) {
    return prefs.getString(key);
  }

  // TODO: 3. handle messages
  void onMessage(message) {
    var body = jsonDecode(message);
    if (body["msg_type"] == TypeMessage.requestLogin) {
      login();
    } else if (body["msg_type"] == TypeMessage.loginSuccess){
      userId = body["pk"];
      userName = body["name"];
    } else if (body["msg_type"] == TypeMessage.text){
      String userPk = userId == body["sender"] ? body["receiver"] : body["sender"];
      MessageChat msg = MessageChat.fromJson({
        "pk": body["random_id"],
        "text": body["text"],
        "created": DateTime.now().toIso8601String(),
        "modified": DateTime.now().toIso8601String(),
        "sender": {
          "pk": body["sender"]
        },
        "recipient": {
          "pk": body["receiver"]
        },
        "out": userId == body["sender"],
        "read": false,

      });
      
      if (chatMessages[userPk] != null ) {
        chatMessages[userPk]?.insert(0, msg);
        notifyListeners();
      }
    } else if (body["msg_type"] == TypeMessage.created){
      String userPk = userId == body["sender"] ? body["receiver"] : body["sender"];
      int? index = chatMessages[userPk]?.indexWhere((m) => m.pk == body["random_id"]);
      if (index !=null && index > -1) {
        chatMessages[userPk]?[index].pk = body["db_id"];
        if (body["sender"] != userId) {
          readMessage(body["db_id"], body["sender"]);
        }
      }
      
    } else {
      print("get message ${message}");
    }
  }

  void connect() {
    // TODO: 1. Connect to websocket server
    String? baseUrl = dotenv.env['SOCKET_URL'];
    _channel = WebSocketChannel.connect(
      Uri.parse("${baseUrl}"),
    );
    // TODO: 2. listen to new message from socket server
    _channel?.stream.listen(onMessage);
  }

  void close() {
    if (_channel != null) {
      _channel?.sink.close();
    }
  }

  void login() {
    String? token = getPref("token");
    if  (token != null && _channel != null) {
      var message = {
        "msg_type": TypeMessage.login,
        "text": "${token}"
      };
      _channel?.sink.add(jsonEncode(message));
    }
  }

  Stream? getChannelStream() {
    return _channel?.stream;
  }

  void getMessages(String groupChatId, int limit)  async {
    String? baseUrl = dotenv.env['API_BASE_URL'];
    String? token = getPref("token");
    List<MessageChat> messages = [];
    isLoading = true;
    notifyListeners();
    if (baseUrl != null && token != null) {
      Dio dio = new Dio();
      print("get message for User ${groupChatId}");
      dio.options.baseUrl = baseUrl;
      dio.options.headers["Authorization"] = "Bearer ${token}";
      final response = await dio
      .get(
        "chat/messages/${groupChatId}/"
      );
      if (response.statusCode == 200) {
        for (var message in response.data['results']) {
           messages.add(MessageChat.fromJson(message));
        }
      }
    }
    
    isLoading = false;
    chatMessages[groupChatId] = messages;
    notifyListeners();
  }

  void readMessage(int msgId, String peerId) {
    if  ( _channel != null) {
      Random random = new Random();
      int id = -random.nextInt(1000000);
      var message = {
        "msg_type": TypeMessage.read,
        "user_pk": peerId,
        "message_id": msgId,

      };
      _channel?.sink.add(jsonEncode(message));

    }
  }

  void sendMessage(String content, int type, String groupChatId, String peerName, String peerId) {
    if  ( _channel != null) {
      Random random = new Random();
      int id = -random.nextInt(1000000);
      var message = {
        "msg_type": type,
        "text": content,
        "user_pk": groupChatId,
        "random_id": id,

      };
      _channel?.sink.add(jsonEncode(message));

      MessageChat msg = MessageChat.fromJson({
        "pk": id,
        "text": content,
        "created": DateTime.now().toIso8601String(),
        "modified": DateTime.now().toIso8601String(),
        "sender": {
          "pk": userId
        },
        "recipient": {
          "pk": groupChatId
        },
        "out": true,
        "read": false,

      });
      if (chatMessages[groupChatId] != null ) {
        chatMessages[groupChatId]?.insert(0, msg);
        notifyListeners();
      }
    }
  }
}

class TypeMessage {
  static const online = 1;
  static const offline = 2;
  static const text = 3;
  static const login = 4;
  static const typing = 5;
  static const read = 6;
  static const error = 7;
  static const created = 8;
  static const newUnread = 9;
  static const requestLogin = 100;
  static const loginSuccess = 101;
  static const loginError = 102;
}

import 'dart:io';
import 'dart:math';
import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:flutter_chat_demo/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:dio/dio.dart';

class ChatProvider {
  final SharedPreferences prefs;
  late WebSocketChannel? _channel;

  ChatProvider({required this.prefs});

  String? getPref(String key) {
    return prefs.getString(key);
  }

  void onMessage(message) {
    var body = jsonDecode(message);
    if (body["type"] == TypeMessage.requestLogin) {
      login();
    } else {
      print("get message ${message}");
    }
  }

  void connect() {
    String? baseUrl = dotenv.env['SOCKET_URL'];
    _channel = WebSocketChannel.connect(
      Uri.parse("${baseUrl}"),
    );
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

  Future<List<MessageChat>> getMessages(String groupChatId, int limit)  async {
    String? baseUrl = dotenv.env['API_BASE_URL'];
    String? token = getPref("token");
    List<MessageChat> messages = [];
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
        print(response.data['results']);
        for (var message in response.data['results']) {
           messages.add(MessageChat.fromJson(message));
        }
      }
    }
    return messages;
  }

  void sendMessage(String content, int type, String groupChatId, String currentUserId, String peerId) {
    if  ( _channel != null) {
      Random random = new Random();
      var message = {
        "msg_type": type,
        "text": content,
        "user_pk": groupChatId,
        "random_id": -random.nextInt(1000000),

      };
      print(message);
      _channel?.sink.add(jsonEncode(message));
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
}

import 'package:flutter_chat_demo/constants/firestore_constants.dart';
import 'package:flutter_chat_demo/models/models.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
class HomeProvider  {
  final SharedPreferences prefs;
  HomeProvider({required this.prefs});

  String? getPref(String key) {
    return prefs.getString(key);
  }

  Future<List<UserChat>> getUsers(String _textSearch) async {
    String? baseUrl = dotenv.env['API_BASE_URL'];
    String? token = getPref("token");
    List<UserChat> users = [];
    if (baseUrl != null && token != null) {
      Dio dio = new Dio();
      dio.options.baseUrl = baseUrl;
      dio.options.headers["Authorization"] = "Bearer ${token}";
      if (_textSearch == "") {
        final response = await dio
        .get(
          "chat/dialogs/"
        );
        if (response.statusCode == 200) {
          for (var user in response.data['results']) {
            print(user);
            users.add(UserChat(
              id: "${user["user"]["pk"]}",
              photoUrl: "",
              nickname: user["user"]["first_name"],
              lastMessage: user["last_message"] != null ? user["last_message"]["text"] : "",
              unread: user["unread_count"],
            ));
          }
        }
      } else {
        final response = await dio
        .get(
          "chat/users/",
          queryParameters: {'search': _textSearch}
        );
        if (response.statusCode == 200) {
          for (var user in response.data['results']) {
            print(user);
            users.add(UserChat(
              id: "${user["pk"]}",
              photoUrl: "",
              nickname: user["first_name"],
              lastMessage: "",
              unread: 0,
            ));
          }
        }
      }
      
    }
    return users;
  }
}

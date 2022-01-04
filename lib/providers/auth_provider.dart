
import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:flutter_chat_demo/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:http/http.dart' as http;

enum Status {
  uninitialized,
  authenticated,
  authenticating,
  authenticateError,
  authenticateCanceled,
}

class AuthProvider extends ChangeNotifier {
  final SharedPreferences prefs;

  Status _status = Status.uninitialized;

  Status get status => _status;

  AuthProvider({
    required this.prefs,
  });

  String? getUserFirebaseId() {
    return prefs.getString(FirestoreConstants.id);
  }

  String? getUserToken() {
    return prefs.getString("token");
  }

  Future<bool> isLoggedIn() async {
    if (prefs.getString("token")?.isNotEmpty == true) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> handleSignIn(String email, String password) async {
    _status = Status.authenticating;
    notifyListeners();
    String? baseUrl = dotenv.env['API_BASE_URL'];
    if (email != "" && password != "" && baseUrl != null) {
      var body = jsonEncode({
        "email": email,
        "password": password
      });
      final response = await http
      .post(
        Uri.parse("${baseUrl}api/login/"),
        headers: {"Content-Type": "application/json"},
        body: body
      );
      if (response.statusCode == 200) {
        var body = jsonDecode(response.body);
        await prefs.setString("token", body['access']);
        _status = Status.authenticated;
        notifyListeners();
        return true;
      } else {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        _status = Status.authenticateError;
        notifyListeners();
        return false;
      }
    
    } else {
      _status = Status.authenticateError;
      notifyListeners();
      return false;
    }
  }

  Future<void> handleSignOut() async {
    _status = Status.uninitialized;
  
  }
}

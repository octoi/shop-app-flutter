import 'dart:convert';
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_app/config.dart';
import 'package:shop_app/models/http_exception.dart';

class Auth with ChangeNotifier {
  late String _token;
  late String _userId;
  late DateTime _expiryDate;
  var _authTimer;

  bool get isAuth {
    return token != null.toString();
  }

  String get token {
    try {
      if (_expiryDate != null &&
          _expiryDate.isAfter(DateTime.now()) &&
          _token != null) {
        return _token;
      }
      return null.toString();
    } catch (err) {
      return null.toString();
    }
  }

  String get userId {
    try {
      return _userId.toString();
    } catch (err) {
      print(err);
      return null.toString();
    }
  }

  Future<void> _authenticate(
    String email,
    String password,
    String urlSegment,
  ) async {
    try {
      final url =
          'https://identitytoolkit.googleapis.com/v1/accounts:$urlSegment?key=$API_KEY';

      final response = await http.post(
        Uri.parse(url),
        body: json.encode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      final responseData = json.decode(response.body);

      if (responseData['error'] != null) {
        throw HttpException(responseData['error']['message']);
      }

      _token = responseData['idToken'];
      _userId = responseData['localId'];
      _expiryDate = DateTime.now().add(
        Duration(seconds: int.parse(responseData['expiresIn'])),
      );

      _autoLogout();
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode({
        'token': _token,
        'userId': _userId,
        'expiryDate': _expiryDate.toIso8601String(),
      });
      prefs.setString('userData', userData);
    } catch (err) {
      throw err;
    }
  }

  Future<void> signup(String email, String password) async {
    return _authenticate(email, password, 'signUp');
  }

  Future<void> login(String email, String password) async {
    return _authenticate(email, password, 'signInWithPassword');
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) return false;

    final extractedUserData =
        json.decode(prefs.getString('userData').toString()) as Map;

    final expiryDate = DateTime.parse(extractedUserData['expiryDate']);
    if (expiryDate.isBefore(DateTime.now())) return false;

    _token = extractedUserData['token'];
    _userId = extractedUserData['userId'];
    _expiryDate = expiryDate;

    _autoLogout();
    notifyListeners();
    return true;
  }

  void logout() async {
    _token = null.toString();
    _expiryDate = DateTime.now();
    _userId = null.toString();
    if (_authTimer != null) {
      _authTimer.cancel();
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }

  void _autoLogout() {
    if (_authTimer != null) {
      _authTimer.cancel();
    }
    final timeToExpiry = _expiryDate.difference(DateTime.now()).inSeconds;
    _authTimer = Timer(Duration(seconds: timeToExpiry), logout);
  }
}

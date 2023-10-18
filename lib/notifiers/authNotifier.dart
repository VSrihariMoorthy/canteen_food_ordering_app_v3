import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:canteen_food_ordering_app_v3/models/user.dart';

class AuthNotifier extends ChangeNotifier {
  
  auth.User? _user;

  auth.User? get user {
    return _user;
  }

  void setUser(auth.User? user) {
    _user = user;
    notifyListeners();
  }

  // Test
  late User _userDetails;

  User? get userDetails => _userDetails;

  setUserDetails(User user) {
    _userDetails = user;
    notifyListeners();
  }
}

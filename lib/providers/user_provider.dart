import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  bool _loading = false;

  UserModel? get user => _user;
  bool get loading => _loading;

  Future<void> load(String uid) async {
    _loading = true;
    notifyListeners();
    _user = await UserService().getUser(uid);
    _loading = false;
    notifyListeners();
  }

  void update(UserModel user) {
    _user = user;
    notifyListeners();
  }

  void clear() {
    _user = null;
    notifyListeners();
  }
}

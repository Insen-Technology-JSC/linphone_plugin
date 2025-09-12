import 'package:shared_preferences/shared_preferences.dart';

const _userName = 'user_name';
const _password = 'password';
const _domain = 'domain';
const _dest = 'dest';

class Storage {
  static final Storage instance = Storage._init();
  Storage._init();

  SharedPreferences? _pref;

  Future<void> init() async {
    _pref = await SharedPreferences.getInstance();
  }

  void storeUser({required String value}) {
    _pref?.setString(_userName, value);
  }

  String get userName => _getStringByKey(_userName);

  void storePassword({required String value}) {
    _pref?.setString(_password, value);
  }

  String get password => _getStringByKey(_password);

  void storeDomain({required String value}) {
    _pref?.setString(_domain, value);
  }

  String get domain => _getStringByKey(_domain);

  void storeDest({required String value}) {
    _pref?.setString(_dest, value);
  }

  String get dest => _getStringByKey(_dest);

  String _getStringByKey(String key) {
    return _pref?.getString(key) ?? '';
  }
}

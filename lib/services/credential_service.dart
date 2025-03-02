import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CredentialService {
  static const _accountsKey = 'user_accounts';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<List<Map<String, String>>> getUserAccounts() async {
    final accountsJson = await _storage.read(key: _accountsKey);
    if (accountsJson != null) {
      final List<dynamic> accountsDynamic = jsonDecode(accountsJson);
      return accountsDynamic
          .map<Map<String, String>>((item) => Map<String, String>.from(item))
          .toList();
    }
    return [];
  }

  Future<void> addUserAccount(String email, String password) async {
    final accounts = await getUserAccounts();
    // Do not add if account already exists.
    if (accounts.any((account) => account['email'] == email)) return;
    accounts.add({'email': email, 'password': password});
    await _storage.write(key: _accountsKey, value: jsonEncode(accounts));
  }

  Future<String?> getPasswordForEmail(String email) async {
    final accounts = await getUserAccounts();
    final account = accounts.firstWhere(
      (account) => account['email'] == email,
      orElse: () => {},
    );
    return account.isEmpty ? null : account['password'];
  }
}

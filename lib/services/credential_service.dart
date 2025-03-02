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

  Future<void> addUserAccount(
      String email, String? password, String authType) async {
    final accounts = await getUserAccounts();
    // Update if account exists, otherwise add new
    final existingIndex =
        accounts.indexWhere((account) => account['email'] == email);
    final accountData = {
      'email': email,
      'password': password ?? '',
      'authType': authType,
    };

    if (existingIndex >= 0) {
      accounts[existingIndex] = accountData;
    } else {
      accounts.add(accountData);
    }

    await _storage.write(key: _accountsKey, value: jsonEncode(accounts));
  }

  Future<Map<String, String>?> getAccountDetails(String email) async {
    final accounts = await getUserAccounts();
    final account = accounts.firstWhere(
      (account) => account['email'] == email,
      orElse: () => {},
    );
    return account.isEmpty ? null : account;
  }
}

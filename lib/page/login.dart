import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nativ/config.dart';
import 'package:nativ/entity/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback login;
  const LoginPage({super.key, required this.login});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameC = TextEditingController();
  final TextEditingController _passwordC = TextEditingController();
  final TextEditingController _namaC = TextEditingController();
  String _status = '';
  bool _isRegister = false;
  bool _isLoading = false;

  @override
  initState() {
    super.initState();
    getUser();
  }

  Future<void> getUser() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    bool isLoggedIn = preferences.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) widget.login();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    final username = _usernameC.text;
    final password = _passwordC.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _status = "Kolom Username dan Password wajib diisi";
        _isLoading = false;
      });
    } else {
      final url = Uri.parse('${CONFIG().BASE_URL}/login');
      var headers = {
        'Content-Type': 'application/json',
      };
      final body = jsonEncode({'username': username, 'password': password});
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        User user = User.fromJson(data);
        setState(() {
          _isLoading = false;
        });

        SharedPreferences preferences = await SharedPreferences.getInstance();
        preferences.setString('username', user.nama);
        preferences.setInt('userid', user.id);
        preferences.setString('user_username', user.username);
        preferences.setBool('isLoggedIn', true);
        widget.login();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRegister() async {
    setState(() {
      _status = "";
      _isLoading = true;
    });

    final username = _usernameC.text;
    final password = _passwordC.text;
    final nama = _namaC.text;

    if (username.isEmpty || password.isEmpty || nama.isEmpty) {
      setState(() {
        _status = "Seluruh kolom wajib diisi";
        _isLoading = false;
      });
    } else {
      final url = Uri.parse('${CONFIG().BASE_URL}/register');
      var headers = {
        'Content-Type': 'application/json',
      };
      final body = jsonEncode({
        'username': username,
        'nama': nama,
        'password': password,
      });
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        User user = User.fromJson(data);
        setState(() {
          _isLoading = false;
        });

        SharedPreferences preferences = await SharedPreferences.getInstance();
        preferences.setString('username', user.nama);
        preferences.setInt('userid', user.id);
        preferences.setString('user_username', user.username);
        preferences.setBool('isLoggedIn', true);
        widget.login();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/nativ.png'),
                const SizedBox(
                  height: 20,
                ),
                Text(_status),
                if (_isRegister)
                  TextField(
                    controller: _namaC,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                    ),
                  ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _usernameC,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                  ),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _passwordC,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24.0),
                _isRegister
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple),
                        onPressed: _isLoading ? null : _handleRegister,
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Register'),
                      )
                    : ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Login'),
                      ),
                _isRegister
                    ? TextButton(
                        onPressed: () {
                          setState(() {
                            _isRegister = false;
                          });
                        },
                        child: const Text("Have Account? Login Here"),
                      )
                    : TextButton(
                        onPressed: () {
                          setState(() {
                            _isRegister = true;
                          });
                        },
                        child: const Text("Dont Have Account? Register Here"),
                      )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

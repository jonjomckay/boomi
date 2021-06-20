import 'package:boomi/main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({Key? key}) : super(key: key);

  @override
  _AuthenticationScreenState createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  String? _account;
  String? _username;
  String? _password;

  late Future _future;

  @override
  void initState() {
    super.initState();

    _future = Future(() async {
      var prefs = await SharedPreferences.getInstance();

      setState(() {
        _account = prefs.getString('authentication.account');
        _username = prefs.getString('authentication.username');
        _password = prefs.getString('authentication.password');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder(
          future: _future,
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.done:
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: _account,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Account ID',
                      ),
                      onChanged: (value) => setState(() {
                        _account = value;
                      }),
                    ),
                    TextFormField(
                      initialValue: _username,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Username',
                      ),
                      onChanged: (value) => setState(() {
                        _username = value;
                      }),
                    ),
                    TextFormField(
                      obscureText: true,
                      initialValue: _password,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Password'
                      ),
                      onChanged: (value) => setState(() {
                        _password = value;
                      }),
                    ),
                    OutlinedButton(
                        onPressed: () async {
                          var prefs = await SharedPreferences.getInstance();

                          var account = _account;
                          var username = _username;
                          var password = _password;

                          if (account != null) {
                            prefs.setString('authentication.account', account);
                          }

                          if (username != null) {
                            prefs.setString('authentication.username', username);
                          }

                          if (password != null) {
                            prefs.setString('authentication.password', password);
                          }

                          if (account != null && username != null && password != null) {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
                          }
                        },
                        child: Text('Save')
                    )
                  ],
                );
              default:
                return Center(child: CircularProgressIndicator());
            }
          },
        )
      ),
    );
  }
}

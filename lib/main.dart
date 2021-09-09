import 'package:boomi/authentication/authentication.dart';
import 'package:boomi/process_reporting/process_reporting_list.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Boomi',
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue
      ),
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<bool> _isAuthenticated;

  @override
  void initState() {
    super.initState();

    _isAuthenticated = Future(() async {
      var prefs = await SharedPreferences.getInstance();

      return
        prefs.containsKey('authentication.account') &&
        prefs.containsKey('authentication.username') &&
        prefs.containsKey('authentication.password');
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAuthenticated,
      builder: (context, snapshot) {
        var isAuthenticated = snapshot.data;
        if (isAuthenticated == null) {
          return Center(child: CircularProgressIndicator());
        }

        return isAuthenticated
            ? ProcessReportingScreen()
            : AuthenticationScreen();
      },
    );
  }
}



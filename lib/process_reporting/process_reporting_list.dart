import 'dart:convert';
import 'dart:developer';

import 'package:boomi/process_reporting/process_reporting_single.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

class ProcessReportingScreen extends StatefulWidget {
  const ProcessReportingScreen({Key? key}) : super(key: key);

  @override
  _ProcessReportingScreenState createState() => _ProcessReportingScreenState();
}

class _ProcessReportingScreenState extends State<ProcessReportingScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();

    _future = Future(() async {
      var prefs = await SharedPreferences.getInstance();

      var account = prefs.getString('authentication.account');
      var username = prefs.getString('authentication.username');
      var password = prefs.getString('authentication.password');

      var response = await http.post(Uri.https('api.boomi.com', '/api/rest/v1/$account/ExecutionRecord/query'), headers: {
        'Authorization': 'Basic ' + base64Encode(utf8.encode('$username:$password')),
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }, body: jsonEncode({"QueryFilter": {}}));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      throw Exception('Something went wrong talking to Boomi: ${response.body}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Process Reporting'),
        ),
        body: Center(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _future,
            builder: (context, snapshot) {
              var error = snapshot.error;
              if (error != null) {
                log('Oops', error: error, stackTrace: snapshot.stackTrace);
                return Text('Something broke');
              }

              var data = snapshot.data;
              if (data == null) {
                return Center(child: CircularProgressIndicator());
              }

              var items = List.from(data['result']);

              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  var item = items[index];
                  var time = DateTime.parse(item['executionTime']);

                  Icon status;
                  switch (item['status']) {
                    case 'ABORTED':
                      status = Icon(Icons.unpublished, color: Colors.grey);
                      break;
                    case 'COMPLETE':
                      status = Icon(Icons.check, color: Colors.green);
                      break;
                    case 'COMPLETE_WARN':
                      status = Icon(Icons.warning, color: Colors.amber);
                      break;
                    case 'DISCARDED':
                      status = Icon(Icons.delete, color: Colors.grey);
                      break;
                    case 'ERROR':
                      status = Icon(Icons.error, color: Colors.red);
                      break;
                    case 'INPROCESS':
                      status = Icon(Icons.play_circle, color: Colors.blue);
                      break;
                    case 'STARTED':
                      status = Icon(Icons.play_circle, color: Colors.grey);
                      break;
                    default:
                      status = Icon(Icons.help, color: Colors.grey);
                      break;
                  }

                  // log(jsonEncode(item));

                  return ListTile(
                    leading: status,
                    title: Text(item['processName']),
                    subtitle: Text('${timeago.format(time)} on ${item['atomName']}'),
                    trailing: Text('${item['executionDuration'][1]} ms'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProcessReportingSingle(id: item['executionId']))),
                  );
                },
              );
            },
          ),
        )
    );
  }
}

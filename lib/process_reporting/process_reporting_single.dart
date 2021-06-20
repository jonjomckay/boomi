import 'dart:convert';
import 'dart:developer';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProcessReportingSingle extends StatefulWidget {
  final String id;

  ProcessReportingSingle({Key? key, required this.id}) : super(key: key);

  @override
  _ProcessReportingSingleState createState() => _ProcessReportingSingleState();
}

class _ProcessReportingSingleState extends State<ProcessReportingSingle> {
  late Future<Map<String, dynamic>> _future;
  late Future<Archive> _future2;

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
      }, body: jsonEncode({
            "QueryFilter": {
              "expression": {
                "argument": [widget.id],
                "operator": "EQUALS",
                "property": "executionId"
              }
            }
          }));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      throw Exception('Something went wrong talking to Boomi: ${response.body}');
    });

    _future2 = Future(() async {
      var prefs = await SharedPreferences.getInstance();

      var account = prefs.getString('authentication.account');
      var username = prefs.getString('authentication.username');
      var password = prefs.getString('authentication.password');

      var response = await http.post(Uri.https('api.boomi.com', '/api/rest/v1/$account/ProcessLog'), headers: {
        'Authorization': 'Basic ' + base64Encode(utf8.encode('$username:$password')),
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }, body: jsonEncode({
        "executionId": widget.id,
        "logLevel": "ALL"
      }));

      if (response.statusCode == 202) {
        var body = jsonDecode(response.body);

        var downloadResponse = await http.get(Uri.parse(body['url']), headers: {
          'Authorization': 'Basic ' + base64Encode(utf8.encode('$username:$password')),
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        });

        while (downloadResponse.statusCode == 202) {
          downloadResponse = await http.get(Uri.parse(body['url']), headers: {
            'Authorization': 'Basic ' + base64Encode(utf8.encode('$username:$password')),
            'Accept': 'application/json',
            'Content-Type': 'application/json'
          });
        }

        if (downloadResponse.statusCode == 200) {
          return ZipDecoder().decodeBytes(downloadResponse.bodyBytes);
        }
      }

      throw Exception('Something went wrong talking to Boomi: ${response.body}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        margin: EdgeInsets.all(16),
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
            if (items.isEmpty) {
              return Text('Could not find the execution');
            }

            var item = items.first;

            log(jsonEncode(item));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['processName']),
                Text(item['executionTime']),
                Text(item['status']),
                Text(item['executionType']),
                Text(item['atomName']),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Inbound Documents', style: TextStyle(
                      fontSize: 24
                    )),
                    SizedBox(height: 16),
                    GridView(
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('# of documents'),
                            Text('${item['inboundDocumentCount']}', style: TextStyle(
                                fontSize: 24
                            )),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Size'),
                            Text('${item['inboundDocumentSize'][1]} bytes', style: TextStyle(
                                fontSize: 24
                            )),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Errored'),
                            Text('${item['inboundErrorDocumentCount']}', style: TextStyle(
                                fontSize: 24
                            )),
                          ],
                        )
                      ],
                    )
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Outbound Documents', style: TextStyle(
                        fontSize: 24
                    )),
                    SizedBox(height: 16),
                    GridView(
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('# of documents'),
                            Text('${item['outboundDocumentCount']}', style: TextStyle(
                                fontSize: 24
                            )),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Size'),
                            Text('${item['outboundDocumentSize'][1]} bytes', style: TextStyle(
                                fontSize: 24
                            )),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Text('${item['executionDuration'][1]} ms'),

                FutureBuilder<Archive>(
                  future: _future2,
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

                    return Text(String.fromCharCodes(data.first.content));
                  }
                )
              ],
            );
          },
        ),
      ),
    );
  }
}
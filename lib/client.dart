import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AtomSphereClient {
  Future<Map<String, dynamic>> getExecutionRecord(String id) async {
    var response = await _executePost('/ExecutionRecord/query', {
      "QueryFilter": {
        "expression": {
          "argument": [id],
          "operator": "EQUALS",
          "property": "executionId"
        }
      }
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Something went wrong talking to Boomi: ${response.body}');
  }

  Future<String> getExecutionLog(String id) async {
    var response = await _executePost('/ProcessLog', {
      "executionId": id,
      "logLevel": "ALL"
    });

    if (response.statusCode == 202) {
      var body = jsonDecode(response.body);

      var downloadResponse = await _executeGetAbsolute(body['url']);

      while (downloadResponse.statusCode == 202) {
        downloadResponse = await _executeGetAbsolute(body['url']);
      }

      if (downloadResponse.statusCode == 200) {
        var archive = ZipDecoder().decodeBytes(downloadResponse.bodyBytes);

        return String.fromCharCodes(archive.first.content);
      }

      if (downloadResponse.statusCode == 204) {
        return 'No logs available';
      }

      if (downloadResponse.statusCode == 404) {
        // TODO
        return 'No logs available';
      }

      if (downloadResponse.statusCode == 504) {
        return 'The Atom is unavailable';
      }
    }

    throw Exception('Something went wrong talking to Boomi: ${response.body}');
  }

  static Future<http.Response> _executeGetAbsolute(String uri) async {
    var prefs = await SharedPreferences.getInstance();

    var username = prefs.getString('authentication.username');
    var password = prefs.getString('authentication.password');

    return await http.get(Uri.parse(uri),
        headers: _createRequestHeaders(username, password)
    );
  }

  static Future<http.Response> _executePost(String uri, Object? body) async {
    var prefs = await SharedPreferences.getInstance();

    var account = prefs.getString('authentication.account');
    var username = prefs.getString('authentication.username');
    var password = prefs.getString('authentication.password');

    return await http.post(Uri.https('api.boomi.com', '/api/rest/v1/$account$uri'),
        headers: _createRequestHeaders(username, password),
        body: jsonEncode(body)
    );
  }

  static Map<String, String> _createRequestHeaders(String? username, String? password) {
    return {
      'Authorization': 'Basic ' + base64Encode(utf8.encode('$username:$password')),
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    };
  }
}
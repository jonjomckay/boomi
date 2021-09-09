import 'dart:convert';
import 'dart:developer';

import 'package:async_builder/async_builder.dart';
import 'package:boomi/client.dart';
import 'package:flutter/material.dart';

class ProcessReportingSingle extends StatefulWidget {
  final String id;

  ProcessReportingSingle({Key? key, required this.id}) : super(key: key);

  @override
  _ProcessReportingSingleState createState() => _ProcessReportingSingleState();
}

class _ProcessReportingSingleState extends State<ProcessReportingSingle> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();

    _future = AtomSphereClient().getExecutionRecord(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        margin: EdgeInsets.all(16),
        child: AsyncBuilder<Map<String, dynamic>>(
          future: _future,
          waiting: (context) => Center(child: CircularProgressIndicator()),
          error: (context, error, stackTrace) {
            log('Oops', error: error, stackTrace: stackTrace);
            return Text('Something broke');
          },
          builder: (context, data) {
            if (data == null) {
              // TODO
              return Text('This should never happen');
            }

            var items = List.from(data['result']);
            if (items.isEmpty) {
              return Text('Could not find the execution');
            }

            var item = items.first;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: EdgeInsets.only(bottom: 8),
                            child: Text(item['processName'], style: TextStyle(
                                fontSize: 16
                            )),
                          ),
                          Container(
                            margin: EdgeInsets.only(bottom: 4),
                            child: Text('Executed on ${item['atomName']}', style: Theme.of(context).textTheme.bodyText2!.copyWith(
                              color: Theme.of(context).textTheme.caption!.color
                            )),
                          ),
                        ],
                      ),
                      Text(item['executionTime'])
                    ],
                  ),
                ),

                Container(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        color: Colors.green,
                        child: Text(item['status']),
                        margin: EdgeInsets.only(right: 4),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      Container(
                        color: Colors.blue,
                        child: Text(item['executionType'].toUpperCase()),
                        margin: EdgeInsets.only(right: 4),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ],
                  ),
                ),

                IntrinsicHeight(
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Column(
                        children: [
                          Text('Count'),
                          Text('${item['inboundDocumentCount']}', style: TextStyle(
                              fontSize: 18
                          )),
                        ],
                      ),
                      VerticalDivider(),
                      Text('Size'),
                      VerticalDivider(),
                      Text('Errored'),
                    ],
                  )
                ),

                ListView.separated(
                  shrinkWrap: true,
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    return Text('Item');
                  },
                  separatorBuilder: (context, index) {
                    return VerticalDivider();
                  },
                ),

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

                ProcessLogs(id: widget.id)
              ],
            );
          },
        ),
      ),
    );
  }
}

class ProcessLogs extends StatefulWidget {
  final String id;

  const ProcessLogs({Key? key, required this.id}) : super(key: key);

  @override
  _ProcessLogsState createState() => _ProcessLogsState();
}

class _ProcessLogsState extends State<ProcessLogs> {
  late Future<String> _future;

  @override
  void initState() {
    super.initState();

    _future = AtomSphereClient().getExecutionLog(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return AsyncBuilder<String>(
      future: _future,
      waiting: (context) => Center(child: CircularProgressIndicator()),
      builder: (context, logs) {
        if (logs == null) {
          return Text('This should never happen');
        }

        return Text(logs);
      },
    );
  }
}

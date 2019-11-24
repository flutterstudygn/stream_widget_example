import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stream_test/stream.dart';
import 'package:stream_test/with_stateful/stateful_b.dart';

class StatefulA extends StatefulWidget {
  static const tag = 'StatefulA';

  @override
  State<StatefulWidget> createState() => _StatefulAState();
}

class _StatefulAState extends State<StatefulA> {
  StreamSubscription _stopwatchListener;

  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    print('[${StatefulA.tag}] on initState');
    _stopwatchListener = stopwatch.listen(
      (_) => setState(() {
        _seconds++;
      }),
    );
    print('[${StatefulA.tag}] start listening stopwatch');
  }

  @override
  void dispose() {
    print('[${StatefulA.tag}] on dispose');
    _stopwatchListener.cancel();
    print('[${StatefulA.tag}] cancel listening stopwatch');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('[${StatefulA.tag}] build called');

    print('Tick from [${StatefulA.tag}]');

    return Scaffold(
      appBar: AppBar(
        title: Text('StatefulA'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              _seconds.toString(),
              textAlign: TextAlign.center,
            ),
            RaisedButton(
              onPressed: () => _stopwatchListener.pause(
                Navigator.of(context)
                    .push(
                  MaterialPageRoute(
                    builder: (_) => StatefulB(_seconds),
                  ),
                )
                    .then(
                  (seconds) {
                    setState(() {
                      _seconds = seconds;
                    });
                  },
                ),
              ),
              child: Text(
                'Push StatefulB',
              ),
            )
          ],
        ),
      ),
    );
  }
}

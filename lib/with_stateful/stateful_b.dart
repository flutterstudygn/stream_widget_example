import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stream_test/stream.dart';

class StatefulB extends StatefulWidget {
  static const tag = 'StatefulB';

  final int _initSeconds;

  const StatefulB(this._initSeconds, {Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _StatefulBState();
}

class _StatefulBState extends State<StatefulB> {
  StreamSubscription _stopwatchListener;

  int _seconds;

  @override
  void initState() {
    super.initState();
    _seconds = widget._initSeconds;

    print('[${StatefulB.tag}] on initState');
    _stopwatchListener = stopwatch.listen(
      (i) => setState(() {
        _seconds++;
      }),
    );
    print('[${StatefulB.tag}] start listening stopwatch');
  }

  @override
  void dispose() {
    print('[${StatefulB.tag}] on dispose');
    _stopwatchListener.cancel();
    print('[${StatefulB.tag}] cancel listening stopwatch');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('[${StatefulB.tag}] build called');

    return WillPopScope(
      // 버튼 이외의 Android OS 화면 밑의 Navigation Bar나 App bar의 back button으로
      // pop하였을 경우의 처리는 따로 해주어야한다.
      onWillPop: () async {
        Navigator.of(context).pop(_seconds);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('StatefulB'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                _seconds?.toString() ?? widget._initSeconds.toString(),
                textAlign: TextAlign.center,
              ),
              RaisedButton(
                onPressed: () => Navigator.of(context).pop(_seconds),
                child: Text(
                  'Pop this page',
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:stream_test/stream.dart';

class StreamBuilderB extends StatelessWidget {
  static const tag = 'StreamBuilderB';

  final int _initialSeconds;

  const StreamBuilderB(this._initialSeconds, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('[$tag] on builder called');

    return Scaffold(
      appBar: AppBar(
        title: Text('StreamBuilderB'),
      ),
      body: StreamBuilder(
        initialData: 0,
        stream: stopwatch,
        builder: (context, snapshot) {
          print('[$tag] on stream builder called');

          print('Tock from [$tag]');

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  (_initialSeconds + snapshot.data).toString(),
                  textAlign: TextAlign.center,
                ),
                RaisedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Pop this page',
                  ),
                ),
                Text(
                    '현재 StreamBuilderB에 가려져있는 Widget인 StreamBuilderA또한 Stream이 업데이트 될 떄마다 build함수가 실행되고있다.'),
              ],
            ),
          );
        },
      ),
    );
  }
}

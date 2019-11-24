import 'package:flutter/material.dart';
import 'package:stream_test/stream.dart';
import 'package:stream_test/with_stream_builder/stream_builder_b.dart';

class StreamBuilderA extends StatelessWidget {
  static const tag = 'StreamBuilderA';

  @override
  Widget build(BuildContext context) {
    print('[$tag] on builder called');

    bool covered = false;

    return Scaffold(
      appBar: AppBar(
        title: Text('StreamBuilderA'),
      ),
      body: StreamBuilder(
        initialData: 0,
        stream: stopwatch,
        builder: (context, snapshot) {
          print('[$tag] on stream builder called');

          // 현재 페이지가 가려졌다면 바로 빈 Widget인 SizedBox를 return한다.
          // 이 처리부분이 없으면 Flutter의 framework는 계속 이하 Widget을 그리게 되고
          // print('Tick from [$tag]')도 출력하게 된다.
          // 만약 해당 코드가 로그가 아니라 시계 소리 출력이었다면 문제가 된다.
          // (혹은 유료 API call이라거나...)
          if (covered) {
            return SizedBox();
          }

          print('Tick from [$tag]');

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  snapshot.data.toString(),
                  textAlign: TextAlign.center,
                ),
                RaisedButton(
                  onPressed: () async {
                    covered = true;
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StreamBuilderB(snapshot.data),
                      ),
                    );
                    covered = false;
                  },
                  child: Text(
                    'Push StreamBuilderB',
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

void d() => StreamBuilder<int>(
      initialData: 0,
      stream: Stream.periodic(Duration(seconds: 1), (i) => i),
      builder: (context, snapshot) => Text(snapshot.data.toString()),
    );

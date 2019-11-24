import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stream_test/with_provider/bloc/stopwatch_bloc.dart';

class ProviderB extends StatelessWidget {
  static const tag = 'ProviderB';

  final StopwatchBloc _periodicBloc;

  const ProviderB(this._periodicBloc, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('[$tag] on builder called');

    return Scaffold(
      appBar: AppBar(
        title: Text('ProviderB'),
      ),
      // .value 생성자를 사용한 이유는 일단 기존 StopwatchBloc의 값을 계속 사용하려면
      // 같은 인스턴스를 리스닝해야하고 .value 생성자의 경우 기본 생성자와 달리
      // Provider가 dispose될 때에 ChangeNotifier의 dispose가 불리지 않기 때문이다.
      body: ChangeNotifierProvider<StopwatchBloc>.value(
        value: _periodicBloc,
        child: Consumer<StopwatchBloc>(
          builder: (context, bloc, buttonAndText) {
            print('[$tag] on consumer builder called');

            print('Tock from [$tag]');

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    bloc.seconds.toString(),
                    textAlign: TextAlign.center,
                  ),
                  buttonAndText
                ],
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              RaisedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Pop this page',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

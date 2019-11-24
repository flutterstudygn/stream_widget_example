import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stream_test/with_provider/bloc/provider_a_bloc.dart';
import 'package:stream_test/with_provider/provider_b.dart';

class ProviderA extends StatelessWidget {
  static const tag = 'ProviderA';

  @override
  Widget build(BuildContext context) {
    print('[$tag] on builder called');

    return Scaffold(
      appBar: AppBar(
        title: Text('ProviderA'),
      ),
      // 여러개의 Provider를 사용하기 위한 클래스.
      // (https://pub.dev/documentation/provider/latest/provider/MultiProvider-class.html)
      body: ChangeNotifierProvider(
        builder: (_) => ProviderABloc()..startStopwatch(),
        // 두 개의 Provider에 대한 Consumer 클래스.
        // (https://pub.dev/documentation/provider/latest/provider/Consumer2-class.html)
        child: Consumer<ProviderABloc>(
          builder: (context, bloc, _) {
            print('[$tag] on consumer builder called');

            print('Tick from [$tag]');

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
                  RaisedButton(
                    onPressed: () => bloc.onCover(
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => ProviderB(bloc.stopwatch)),
                      ),
                    ),
                    child: Text(
                      'Push ProviderB',
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

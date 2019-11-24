import 'dart:async';

import 'package:flutter/foundation.dart';

/// 1초 단위로 증가하는 초시계.
class StopwatchBloc extends ChangeNotifier {
  static const tag = 'StopwatchBloc';

  /// 초마다 수를 증가시키는 Stream.
  final Stream _stopwatch = Stream.periodic(
    Duration(seconds: 1),
    (i) => i,
  );

  StreamSubscription _stopwatchListener;

  int _seconds = 0;

  int get seconds => _seconds;

  @override
  void dispose() {
    print('[$tag] on disposed');
    _stopwatchListener.cancel();
    print('[$tag] _stopwatchListener canceled');
    print('[$tag] disposed');
    super.dispose();
  }

  void start() {
    print('[$tag] on listen');
    _stopwatchListener ??= _stopwatch.listen((i) {
      _seconds = i + 1;
      notifyListeners();
    });
  }
}

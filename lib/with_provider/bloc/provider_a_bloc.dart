import 'package:flutter/cupertino.dart';
import 'package:stream_test/with_provider/bloc/stopwatch_bloc.dart';

/// [Navigator]에 의한 [Widget]의 상태 관리 Bloc.
class ProviderABloc extends ChangeNotifier {
  final StopwatchBloc _stopwatch = StopwatchBloc();

  StopwatchBloc get stopwatch => _stopwatch;

  int get seconds => _stopwatch?.seconds;

  @override
  void dispose() {
    _stopwatch.dispose();
    super.dispose();
  }

  void startStopwatch() {
    _stopwatch.addListener(notifyListeners);
    _stopwatch.start();
  }

  /// [Navigator.push]에 의해 다른 [Widget]에게 덮히는 경우 [_stopwatch]에 대한
  /// 리스닝을 해제한 후 [Navigator.pop]되어 다시 드러났을 때 [_stopwatch]에 대한
  /// 리스닝을 다시 시작한다.
  void onCover(Future resumeSignal) async {
    _stopwatch.removeListener(notifyListeners);
    await resumeSignal;
    _stopwatch.addListener(notifyListeners);
  }
}

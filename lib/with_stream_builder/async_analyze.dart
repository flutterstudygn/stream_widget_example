/// StreamBuilder를 한 번 분석해보자.
/// 기존 주석은 신경 쓰지않고 가볍게 분석하기에 기존 dartDoc의 내용을 보고싶다면
/// 공식 홈페이지 문서나 실제 파일을 보길 바란다.
/// 그리고 중요하지 않은 부분은 그냥 넘어간다.

import 'dart:async' show Future, Stream, StreamSubscription;

/// 실제 소스에선 framework.dart를 import하지만 직접적으로 import하는 법을 몰라
/// widget.dart로 대체한다. 굳이 이러는 이유는 dartDoc을 이용해 class에 대한 링크를 하기 위함이다.
//import 'framework.dart';
import 'package:flutter/widgets.dart';

/// [StreamBuilder]의 Base class이다.
/// abstract class로서 직접 인스턴스화 하지 못하며 상속하여 사용해야한다.
/// [StatefulWidget]을 상속 받아 [State]를 관리하므로써 [Widget]에 [Stream]으로부터 오는 데이터를 반영한다.
/// Generic 요소인 [T]는 [Stream]을 통해 들어오는 데이터 형이며 [S]는 [T]로 타입 지정된 [AsyncSnapshot]이다.
abstract class StreamBuilderBase<T, S> extends StatefulWidget {
  /// 생성자에서 데이터를 받아올 [stream]을 받는다.
  const StreamBuilderBase({Key key, this.stream}) : super(key: key);

  /// [StreamBuilder]에서 준 [Stream]이다.
  final Stream<T> stream;

  /// 초기값을 [AsyncSnapshot]담아 반환한다.
  S initial();

  /// [stream]에 연결됨을 반영하는 [AsyncSnapshot]을 반환한다.
  ///
  /// 기본적으론 [current]를 그대로 반환한다.
  S afterConnected(S current) => current;

  /// [stream]을 통해 들어온 데이터를 반영하는 [AsyncSnapshot]을 반환한다.
  S afterData(S current, T data);

  /// [stream]을 통해 들어온 에러를 반영하는 [AsyncSnapshot]을 반환한다.
  ///
  /// 기본적으론 [current]를 그대로 반환한다.
  S afterError(S current, Object error) => current;

  /// [stream]의 종료와 마지막 데이터를 반영하는 [AsyncSnapshot]을 반환한다.
  ///
  /// 기본적으론 [current]를 그대로 반환한다.
  S afterDone(S current) => current;

  /// [stream]에 연결이 해제됨을 반영하는 [AsyncSnapshot]을 반환한다.
  ///
  /// 기본적으론 [current]를 그대로 반환한다.
  S afterDisconnected(S current) => current;

  /// [currentSummary]를 반영한 [Widget]을 반환한다.
  Widget build(BuildContext context, S currentSummary);

  @override
  State<StreamBuilderBase<T, S>> createState() =>
      _StreamBuilderBaseState<T, S>();
}

/// [StreamBuilderBase]의 [State].
class _StreamBuilderBaseState<T, S> extends State<StreamBuilderBase<T, S>> {
  /// [StreamBuilderBase.stream]에 대한 리스너.
  StreamSubscription<T> _subscription;

  /// [_subscription]이 가져오는 값과 [Stream]과의 연결 상태인 [ConnectionState]를 반영한 [AsyncSnapshot].
  S _summary;

  /// [StreamBuilderBase]의 Subclass가 구현한 initial 메서드를 통해 [_summary]를 초기화한다.
  /// [StreamBuilder]의 경우 여기서 생성자에서 넣어준 initialData와 연결 상태 none을 담은 [AsyncSnapshot]가 된다.
  /// 이후 [StreamBuilderBase.stream]을 구독한다.
  @override
  void initState() {
    super.initState();
    _summary = widget.initial();
    _subscribe();
  }

  /// [oldWidget]의 stream과 새로운 widget의 stream이 다르다면 [_subscription]을 확인한다.
  /// [_subscription]이 null이 아니라면 구독 취소 후 [_summary]를 afterDisconnected로 갱신한다.
  /// 이후 새로운 stream을 구독한다.
  @override
  void didUpdateWidget(StreamBuilderBase<T, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream) {
      if (_subscription != null) {
        _unsubscribe();
        _summary = widget.afterDisconnected(_summary);
      }
      _subscribe();
    }
  }

  /// [StreamBuilderBase]의 Subclass가 구현한 build 메서드를 불러 Widget을 반환한다.
  /// setState가 될 때마다 돌게 되므로 최신 데이터를 가진 [_summary]가 Widget에 반영된다.
  /// Subclass의 build가 도는 것으로 framework로의 최종적인 Widget 제공은 여기서 이루어진다고 볼 수 있다.
  @override
  Widget build(BuildContext context) => widget.build(context, _summary);

  /// Widget이 dispose됨과 동시에 stream을 구독 취소 한다.
  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  /// Stream 구독.
  /// Stream의 각 상황에 대한 반영을 위해 상황별 callback함수를 등록하며
  /// 해당 결과를 widget에 반영하기위해 [setState]를 호출한다.
  /// 마지막의 afterConnected 함수는 데이터의 변화 없이 연결 상태만 변하기에 [setState]를 호출하지 않는다.
  void _subscribe() {
    if (widget.stream != null) {
      _subscription = widget.stream.listen((T data) {
        setState(() {
          _summary = widget.afterData(_summary, data);
        });
      }, onError: (Object error) {
        setState(() {
          _summary = widget.afterError(_summary, error);
        });
      }, onDone: () {
        setState(() {
          _summary = widget.afterDone(_summary);
        });
      });
      _summary = widget.afterConnected(_summary);
    }
  }

  /// Stream 구독 취소.
  /// [didUpdateWidget] 때의 [_summary] 처리를 위해 [_subscription]을 null로 초기화한다.
  void _unsubscribe() {
    if (_subscription != null) {
      _subscription.cancel();
      _subscription = null;
    }
  }
}

/// 비동기 연산에 대한 연결 상태.
enum ConnectionState {
  /// 비동기 연산에 연결되지 않음.
  ///
  /// 예) [FutureBuilder]의 [FutureBuilder.future]나 [StreamBuilder]의 [StreamBuilder.future]가 null인 경우.
  none,

  /// 비동기 연산에 연결되었으며 데이터를 기다리고 있음.
  waiting,

  /// 동적인 연산에 연결됨.
  ///
  /// 예) [Stream]이 일부 데이터를 반환했지만 아직 끝나지 않았을 때.
  active,

  /// 연결된 비동기 연산이 종료됨.
  done,
}

/// 최근 비동기 연산([Stream][Future])과의 상호 작용 결과를 나타내는 클래스.
/// [StreamBuilder]의 경우 [T]는 [StreamBuilder]의 제네릭 타입과 같다.
/// (StreamBuilder<T> extends StreamBuilderBase<T, AsyncSnapshot<T>)
@immutable
class AsyncSnapshot<T> {
  /// [connectionState]을 가진 [AsyncSnapshot]을 생성.
  /// 옵션 값인 [data]와 [error]은 공존할 수 없음.
  const AsyncSnapshot._(this.connectionState, this.data, this.error)
      : assert(connectionState != null),
        assert(!(data != null && error != null));

  /// 아무것도 없는 [AsyncSnapshot] 생성. 이름 잘 지음. 여기 async.dart 쓰이는 곳 없음.
  const AsyncSnapshot.nothing() : this._(ConnectionState.none, null, null);

  /// [state]와 [data]를 가진 [AsyncSnapshot]를 생성
  const AsyncSnapshot.withData(ConnectionState state, T data)
      : this._(state, data, null);

  /// [state]와 [error]를 가진 [AsyncSnapshot]를 생성
  const AsyncSnapshot.withError(ConnectionState state, Object error)
      : this._(state, null, error);

  /// 현재의 비동기 연산과의 연결 상태.
  final ConnectionState connectionState;

  /// 비동기 연산으로부터 받은 마지막 데이터
  ///
  /// [error]가 null이 아니라면 [data]는 null.
  ///
  /// 만약 비동기 연산이 아직 값을 반환하지 않았다면 [data]는 관련된 widget이 특정한
  /// 초기 값을 가지게된다.
  /// [FutureBuilder.initialData]와 [StreamBuilder.initialData] 참조.
  final T data;

  /// 마지막으로 받은 데이터를 반환하며 데이터가 없다면 error를 throw한다.
  ///
  /// [error]가 있거나 [error]와 [data] 둘 다 없다면 throw한다.
  T get requireData {
    if (hasData) return data;
    if (hasError) throw error;
    throw StateError('Snapshot has neither data nor error');
  }

  /// 비동기 연산으로부터 받은 마지막 error 객체.
  ///
  /// [data]가 null이 아니라면 [error]는 null.
  final Object error;

  /// 연결 상태만 변경된 [AsyncSnapshot]를 반환
  AsyncSnapshot<T> inState(ConnectionState state) =>
      AsyncSnapshot<T>._(state, data, error);

  bool get hasData => data != null;

  bool get hasError => error != null;

  @override
  String toString() => '$runtimeType($connectionState, $data, $error)';

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! AsyncSnapshot<T>) return false;
    final AsyncSnapshot<T> typedOther = other;
    return connectionState == typedOther.connectionState &&
        data == typedOther.data &&
        error == typedOther.error;
  }

  @override
  int get hashCode => hashValues(connectionState, data, error);
}

/// 비동기적 상호 작용으로 widget을 build할 때 쓰이는 함수.
///
/// [StreamBuilder]나 [FutureBuilder]의 builder 파라미터로 쓰인다.
typedef AsyncWidgetBuilder<T> = Widget Function(
    BuildContext context, AsyncSnapshot<T> snapshot);

/// Stream으로부터 데이터가 올 때마다 이에 맞춰 widget을 갱신하는 widget.
class StreamBuilder<T> extends StreamBuilderBase<T, AsyncSnapshot<T>> {
  /// [initialData]는 [stream]으로부터 아직 데이터가 오지 않은 경우 사용할 초기값.
  ///
  /// [stream]은 비동기 데이터를 받아올 데이터 소스.
  ///
  /// [builder]는 [stream]으로 부터 받은 데이터를 실제로 반영할 widget 생성 함수.
  /// [AsyncWidgetBuilder]참조.
  const StreamBuilder({
    Key key,
    this.initialData,
    Stream<T> stream,
    @required this.builder,
  })  : assert(builder != null),
        super(key: key, stream: stream);

  /// [stream]으로 부터 받은 데이터를 실제로 반영할 widget 생성 함수.
  final AsyncWidgetBuilder<T> builder;

  /// [stream]으로부터 아직 데이터가 오지 않은 경우 사용할 초기값.
  final T initialData;

  /// [initialData]를 [AsyncSnapshot]에 담아 반환한다.
  /// [StreamBuilder]가 첫 frame을 그리기 전 실행된다.
  /// [StreamBuilderBase.initState] 참조.
  @override
  AsyncSnapshot<T> initial() =>
      AsyncSnapshot<T>.withData(ConnectionState.none, initialData);

  /// [current]의 연결 상태만 [ConnectionState.waiting]로 변경해 반환한다.
  /// 만약 [initialData]가 있다면 data는 [initialData]를 가지게 된다.
  /// [stream]과 연결됐을 때 실행된다.
  /// [StreamBuilderBase._subscribe] 참조.
  @override
  AsyncSnapshot<T> afterConnected(AsyncSnapshot<T> current) =>
      current.inState(ConnectionState.waiting);

  /// [current]에 [data]를 담아 연결 상태를 [ConnectionState.active]로 변경해 반환한다.
  /// [stream]으로 부터 데이터가 들어왔을 때 실행된다.
  /// [StreamBuilderBase._subscribe] 참조.
  @override
  AsyncSnapshot<T> afterData(AsyncSnapshot<T> current, T data) {
    return AsyncSnapshot<T>.withData(ConnectionState.active, data);
  }

  /// [current]에 [error]를 담아 연결 상태를 [ConnectionState.active]로 변경해 반환한다.
  /// [stream]으로 부터 에러가 들어왔을 때 실행된다.
  /// [StreamBuilderBase._subscribe] 참조.
  @override
  AsyncSnapshot<T> afterError(AsyncSnapshot<T> current, Object error) {
    return AsyncSnapshot<T>.withError(ConnectionState.active, error);
  }

  /// [current]의 연결 상태만 [ConnectionState.done]로 변경해 반환한다.
  /// [stream]의 작업이 모두 끝나고 마지막 데이터가 들어올 때 실행된다.
  /// [StreamBuilderBase._subscribe] 참조.
  @override
  AsyncSnapshot<T> afterDone(AsyncSnapshot<T> current) =>
      current.inState(ConnectionState.done);

  /// [current]의 연결 상태만 [ConnectionState.none]으로 변경해 반환한다.
  /// [stream]과 연결이 해제되고 실행된다.
  /// 하지만 builder를 돌리지 않는 dispose시에는 실행되지 않는다.
  /// [StreamBuilderBase.didUpdateWidget] 참조.
  @override
  AsyncSnapshot<T> afterDisconnected(AsyncSnapshot<T> current) =>
      current.inState(ConnectionState.none);

  @override
  Widget build(BuildContext context, AsyncSnapshot<T> currentSummary) =>
      builder(context, currentSummary);
}

/// 여긴 보너스
/// [StreamBuilderBase]와 다를 것 없다.
class FutureBuilder<T> extends StatefulWidget {
  /// [future]는 StreamBuilder의 stream과 같다고 생각하면 된다.
  /// [initialData]와 [builder]는 StreamBuilder의 그 것과 같다.
  const FutureBuilder({
    Key key,
    this.future,
    this.initialData,
    @required this.builder,
  })  : assert(builder != null),
        super(key: key);

  /// 데이터 하나 주는 Stream 혹은 하나씩 모이면 Stream이라고 생각하자.
  final Future<T> future;

  /// [ConnectionState.active]만 안쓰이고 Stream의 그 것과 같다.
  final AsyncWidgetBuilder<T> builder;

  /// 상동(위와 같다는 말이다.)
  final T initialData;

  @override
  State<FutureBuilder<T>> createState() => _FutureBuilderState<T>();
}

class _FutureBuilderState<T> extends State<FutureBuilder<T>> {
  /// An object that identifies the currently active callbacks. Used to avoid
  /// calling setState from stale callbacks, e.g. after disposal of this state,
  /// or after widget reconfiguration to a new Future.
  Object _activeCallbackIdentity;
  AsyncSnapshot<T> _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot =
        AsyncSnapshot<T>.withData(ConnectionState.none, widget.initialData);
    _subscribe();
  }

  @override
  void didUpdateWidget(FutureBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.future != widget.future) {
      if (_activeCallbackIdentity != null) {
        _unsubscribe();
        _snapshot = _snapshot.inState(ConnectionState.none);
      }
      _subscribe();
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _snapshot);

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    if (widget.future != null) {
      final Object callbackIdentity = Object();
      _activeCallbackIdentity = callbackIdentity;
      widget.future.then<void>((T data) {
        if (_activeCallbackIdentity == callbackIdentity) {
          setState(() {
            _snapshot = AsyncSnapshot<T>.withData(ConnectionState.done, data);
          });
        }
      }, onError: (Object error) {
        if (_activeCallbackIdentity == callbackIdentity) {
          setState(() {
            _snapshot = AsyncSnapshot<T>.withError(ConnectionState.done, error);
          });
        }
      });
      _snapshot = _snapshot.inState(ConnectionState.waiting);
    }
  }

  void _unsubscribe() {
    _activeCallbackIdentity = null;
  }
}

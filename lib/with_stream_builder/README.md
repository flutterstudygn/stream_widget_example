# StreamBuilder를 사용해보자.

StreamBuilder를 사용하여 AsyncSnapshot을 통해 Widget을 갱신한다.



## Widget 갱신.

StreamBuilder는 stream이란 파라미터로 데이터 소스가 되는 Stream을 등록하고 데이터를 전달해주는 AsyncSnapshot을 통해 Widget을 갱신한다. 그렇게 데이터가 갱신되면 StreamBuilder의 또다른 파라미터인 builder에서 만들어지는 Widget에 사용할 수 있게된다. StreamBuilder에 등록된 Stream의 lifetime은 등록되고부터 StreamBuilder가 dispose 되기까지이다. StreamBuilder 내부적으로 Stream을 listen하고 해당 subscription의 handling 함수(onData, onError 등) 마다 AsyncSnapshot을 해당 값에 맞게 갱신한다. 이를 바로 builder함수에 전해주며 Widget이 갱신되고 StreamBuilder가 dispose 될 때에 StreamSubscription을 cancel하기 때문에 Subscription이나 State에 대한 직접적인 관리는 전혀 신경 쓸게 없다.

```dart
// int형 데이터를 다루는 간단한 StreamBuilder 예제이다. 직접 사용해보면 더 많은 기능들이 있기에 공식 홈페이지 문서를 참고하여 여러가지 시도해보자.
// 1초에 1씩 증가하는 숫자를 그리는 StreamBuilder이다.
StreamBuilder<int>(
  initialData: 0, // 초기값. 아래의 stream으로부터 아직 값을 받지 못했을 경우 initialData가 builder의 snapshot으로 들어오게된다.
  stream: Stream.periodic(Duration(seconds: 1), (i) => i), // StreamBuilder의 데이터 소스 Stream을 등록하는 부분.
  builder: (context, snapshot) => Text(snapshot.data.toString()), // 실질적으로 데이터를 사용할 Widget을 빌드하는 부분.
);
```



## Subscription 관리.

pause() 말고는 StreamBuilder가 다 해준다.

async.dart파일에 작성되어 있으며 이를 분석한 [async_analyze.dart]( https://github.com/flutterstudygn/stream_widget_example/blob/master/lib/with_stream_builder/async_analyze.dart)를 업로드했으니 참고하길 바란다.

### 1. Subscription의 pause().

StreamBuilder를 사용하게되면 다른 Widget이 push되어 가려진 경우 subscription을 pause()하지 못한다. Subscription의 관리를 StreamBuilder 내부적으로하기 때문이다. 따라서 build()가 불리는 것을 막을 수 없으므로 build()가 불렸을 때 아무것도 하지 않게 하는 걸로 해결한다.

```dart
class Foo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 다른 Widget에 의해 가려졌는지 여부를 나타내는 변수
    bool covered = false;

    return Scaffold(
      body: StreamBuilder(
        stream: someStream,
        builder: (context, snapshot) {
          // 현재 페이지가 가려졌다면 바로 빈 Widget인 SizedBox를 return한다.
          if (covered) {
            return SizedBox();
          }

          return RaisedButton(
            onPressed: () async {
              // 현재 Widget이 다른 Widget의 push에 의해 가려졌다고 상태 변경.
              covered = true;
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AnotherPage(),
                ),
              );
              // 다른 Widget이 pop되어 현재 Widget이 드러났다고 상태 변경.
              covered = false;
            },
            child: Text(
              'Push another page',
            ),
          );
        },
      ),
    );
  }
}
```



## 제한 사항.

예제와 같이 스톱 워치의 경우 새로 push된 Widget에 현재 값을 전달해주어서 계속 값이 연속되게할 수 있었다. 두 Widget 모두 타이밍에 차이는 있지만(이미 스톱 워치로서 문제가 있다;) 똑같이 수를 올리고 있기 때문이다. 하지만 그렇기에 계속 값이 갱신되면 안되는 경우에는 사용하기가 불편하다. 예를들어 WidgetA와 WidgetB가 있을 경우 WidgetA에 WidgetB가 push되면 WidgetA는 당시의 랩타임을 가지고 있다가 WidgetB가 pop되면 해당 랩타임을 그대로 보여준다고 하자. 구현 못할 건 없지만 굳이 이렇게 해야하나 싶다.

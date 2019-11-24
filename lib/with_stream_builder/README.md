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

# 이 밑으로는 Stateful 복붙 작성 예정.

## Stream 관리.

Stream으로 부터 데이터를 받아오기위해선 해당 Stream을 listen하여야한다. 이에대해선 이미 위에 설명이 되었으니 넘어간다.
그렇담 Widget이 dispose되어 더 이상 Stream으로부터 데이터가 필요없는 경우는 어떻게 해야할까?
간단하다. dispose()메서드에서 Stream을 listening하던 StreamSubscription을 cancel하면 된다.

```dart
@override
void dispose() {
  subscription.cancel();
  super.dispose();
}
```

그렇다면 다른 Widget이 push되어 기존 Widget이 더이상 그려질 필요가 없고 state 또한 갱신되지 않아도 된다면 어떨까? 
만약 계속 Stream을 listening하여 state를 갱신한다면 의미 없이 build함수를 돌며 리소스를 낭비할 수 있으며 
경우에 따라 state가 변경되지 않아야 할 수도 있다.

이런 경우 StreamSubscription의 pause()메소드를 활용하면 된다.
pause()메소드는 resumeSignal이라는 이름의 Future를 받는데 이는 pause()가 실행되면 Stream을 listnening하는 것을 잠시 중단했다가
resumesSignal의 작업이 끝났을 때 다시 listen을 하도록 되어있다.
그런데 Navigator.push()메소드는 pop됐을 때 데이터를 받을 수 있도록 Future<dynamic>을 반환하도록 되어있다.
이를 활용하여 resumeSignal로 Navigator.push()의 반환값을 주면 push됐을 때 listen을 멈추었다가 pop되었을 때 다시 시작할 수 있다.
(cancel과 pause는 다르다. cancel은 Stream과의 연결을 완전 끊어 새로 listen을 해야 Stream으로 값을 받을 수 있고 그렇게하면 Stream의 데이터를
처음부터 받기 때문에 값의 순서가 의미가 있는 경우 오류를 범하게된다. pause의 경우 잠시 받는 것을 멈추는 것으로 resume했을시 데이터를 이어받게된다.)

```dart
subscription.pause(
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => NewWidget(),
    ),
  ),
);
```

그리고 위의 경우 만약 새로이 push된 Widget에서 Button을 이용해 pop을 할 경우 pop과 함깨 밑에 깔려있던 Widget에 데이터를 전해주어야하는 상황이라면
Button의 onPressed외의 추가적인 pop처리를 해주어야 한다. 바로 app bar나 bottom bar의 back button으로인한 pop의 처리이다. 이는 WillPopScope라는 
Widget을 통해 한다.

WillPopScop으로 새로이 push된 Widget을 감싸고 onWillPop이라는 파라미터에서 추가적인 작업을 해주면 된다. onWillPop의 반환 값이 Future<bool>인데
이부분이 조금 해깔릴 수 있다. 간단하게는 pop을 하려면 true를 아니라면 false를 반환해주면 되는데 지금의 경우 false를 반환해주어야 한다.
이유는 onWillPop을 통해선 값을 전달할 수가 없기에 Navigator.pop()을 통해 값을 전달하고 onWillPop에선 false를 반환해 pop이 중복되지 않게 해야하기 
때문이다. Widget의 이름이 WillPopScope인 이유가 여기 있다. WillPop즉 Pop을 할지 말지에 대해 결정하는 Scope를 주는 샘인 것이다. 여기서 true를
반환한다면 pop이 중복되어 깔려있던 바로 밑의 Widget까지 pop되어버린다.

```dart
return WillPopScope(
  onWillPop: () async {
    Navigator.of(context).pop(data);
    return false;
  },
  child: SometingToShow(),
);
```

자 여기서 또 만약 pop된 Widget에서 전해준 데이터를 드러난 Widget의 state에 적용시키려면? 간단하다 Navigator.push()의 반환값인 Future의 값을
받아서 setState()함수를 통해 적용하면 된다.

```dart
subscription.pause(
  Navigator.of(context)
      .push(
        MaterialPageRoute(
          builder: (_) => NewWidget(),
        ),
      )
      .then((data) => setState(() => _data = data)),
);
```

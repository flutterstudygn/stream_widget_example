# StatefulWidget의 State을 사용해보자.

StatefulWidget을 사용하여 setState()함수로 Widget을 갱신한다.

## Widget 갱신.

StatefulWidget은 해당 Widget의 상태를 나타내는 state를 가지고있다. state의 lifetime은 initState()에서 dispose()사이이며 이를 갱신하기 위해선 setState()라는 함수를 불러주면 된다. 이를 위해 Stream을 listen하여 Stream을 통해 값이 들어올 때마다 해당 값을 가지고 Widget을 갱신한다. 이는 Stream.listen을 통해 반환되는 StreamSubscription의 onData()메소드에 정의해주면 된다.

```dart
StreamSubscription subscription = someStream.listen(
  (data) => setState(() {
    _data = data;
  }),
);
```

## Subscription 관리.

### 1. Subscription의 cancel().

Widget이 dispose되어 더 이상 Stream으로부터 데이터가 필요없는 경우는 어떻게 해야할까? 간단하다. dispose()메서드에서 Stream을 listening하던 StreamSubscription을 cancel하면 된다.

```dart
@override
void dispose() {
  subscription.cancel();
  super.dispose();
}
```

### 2. Subscription의 pause().

다른 Widget이 push되어 기존 Widget이 더이상 그려질 필요가 없고 state 또한 갱신되지 않아도 된다면 어떨까? 만약 계속 Stream을 listening하여 state를 갱신한다면 의미 없이 build함수를 돌며 리소스를 낭비할 수 있으며 경우에 따라 state가 변경되지 않아야 할 수도 있다.

이런 경우 StreamSubscription의 pause()메소드를 활용하면 된다. pause()메소드는 resumeSignal이라는 이름의 Future를 받는데 이는 pause()가 실행되면 Stream을 listnening하는 것을 잠시 중단했다가 resumesSignal의 작업이 끝났을 때 다시 listen을 하도록 되어있다. 그런데 Navigator.push()메소드는 pop됐을 때 데이터를 받을 수 있도록 Future<dynamic>을 반환하도록 되어있다. 이를 활용하여 resumeSignal로 Navigator.push()의 반환값을 주면 push됐을 때 listen을 멈추었다가 pop되었을 때 다시 시작할 수 있다. 
(cancel과 pause는 다르다. cancel은 Stream과의 연결을 완전 끊어 새로 listen을 해야 Stream으로 값을 받을 수 있고 그렇게하면 Stream의 데이터를 처음부터 받기 때문에 값의 순서가 의미가 있는 경우 오류를 범하게된다. pause의 경우 잠시 받는 것을 멈추는 것으로 resume했을시 데이터를 이어받게된다.)

```dart
subscription.pause(
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => NewWidget(),
    ),
  ),
);
```

## 특이사항.

### 1. Back button에 의한 Navigator.pop()의 처리.

새로이 push된 Widget에서 Button을 이용해 pop을 할 경우 pop과 함께 밑에 깔려있던 Widget에 데이터를 전해주어야하는 상황이라면 Button의 onPressed외의 추가적인 pop처리를 해주어야 한다. 바로 app bar나 bottom bar의 back button으로인한 pop의 처리이다. 이는 WillPopScope라는 Widget을 통해 한다.

WillPopScop으로 새로이 push된 Widget을 감싸고 onWillPop이라는 파라미터에서 추가적인 작업을 해주면 된다. onWillPop의 반환 값이 Future<bool>인데 이부분이 조금 해깔릴 수 있다. 간단하게는 pop을 하려면 true를 아니라면 false를 반환해주면 되는데 지금의 경우 false를 반환해주어야 한다. 이유는 onWillPop을 통해선 값을 전달할 수가 없기에 Navigator.pop()을 통해 값을 전달하고 onWillPop에선 false를 반환해 pop이 중복되지 않게 해야하기 때문이다. Widget의 이름이 WillPopScope인 이유가 여기 있다. WillPop즉 Pop을 할지 말지에 대해 결정하는 Scope를 주는 샘인 것이다. 여기서 true를 반환한다면 pop이 중복되어 깔려있던 바로 밑의 Widget까지 pop되어버린다.

```dart
return WillPopScope(
  onWillPop: () async {
    Navigator.of(context).pop(data);
    return false;
  },
  child: SometingToShow(),
);
```

### 2. Navigator.push()가 받아온 데이터를 가지고 바로 Widget 갱신.
pop된 Widget에서 전해준 데이터를 드러난 Widget의 state에 적용시키려면? 간단하다 Navigator.push()의 반환값인 Future의 값을 받아서 setState()함수를 통해 적용하면 된다.

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

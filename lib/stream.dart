import 'dart:async';

Stream get stopwatch => Stream.periodic(
      Duration(seconds: 1),
      (i) => i + 1,
    );

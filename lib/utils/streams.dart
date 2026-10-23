import 'dart:async';

// Spojí dva živé proudy dat do jednoho. Kdykoli jeden z nich pošle novou
// hodnotu (a už máme hodnotu i z druhého), zavolá "combine" a pošle výsledek.
//
// Používá se třeba pro menu (produkty + kategorie) nebo pro obsluhu
// (nedokončené objednávky + dnešní objednávky).
Stream<R> combineStreams<A, B, R>(
  Stream<A> first,
  Stream<B> second,
  R Function(A a, B b) combine,
) {
  late final StreamController<R> controller;
  StreamSubscription<A>? firstSubscription;
  StreamSubscription<B>? secondSubscription;
  A? lastA;
  B? lastB;
  var hasA = false;
  var hasB = false;

  void emit() {
    if (hasA && hasB) controller.add(combine(lastA as A, lastB as B));
  }

  controller = StreamController<R>(
    onListen: () {
      firstSubscription = first.listen(
        (value) {
          lastA = value;
          hasA = true;
          emit();
        },
        onError: controller.addError,
      );
      secondSubscription = second.listen(
        (value) {
          lastB = value;
          hasB = true;
          emit();
        },
        onError: controller.addError,
      );
    },
    onCancel: () async {
      await firstSubscription?.cancel();
      await secondSubscription?.cancel();
    },
  );
  return controller.stream;
}

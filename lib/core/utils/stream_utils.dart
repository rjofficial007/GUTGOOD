import 'dart:async';

class StreamUtils {
  /// Combines multiple streams into one, emitting a list of all latest values.
  static Stream<List<T>> combineLatest<T>(Iterable<Stream<T>> streams) {
    final controllers = <StreamSubscription<T>>[];
    final latestValues = List<T?>.filled(streams.length, null);
    final hasValue = List<bool>.filled(streams.length, false);
    final controller = StreamController<List<T>>();

    void update(int index, T value) {
      latestValues[index] = value;
      hasValue[index] = true;

      if (hasValue.every((h) => h)) {
        controller.add(List<T>.from(latestValues.whereType<T>()));
      }
    }

    int i = 0;
    for (final stream in streams) {
      final index = i++;
      controllers.add(stream.listen(
        (value) => update(index, value),
        onError: controller.addError,
        onDone: () {
          if (controllers.every((s) => s.isPaused)) {
            controller.close();
          }
        },
      ));
    }

    controller.onCancel = () {
      for (final sub in controllers) {
        sub.cancel();
      }
    };

    return controller.stream;
  }
}

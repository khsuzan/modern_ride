import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_ride/core/utils/bloc_transformers.dart';

void main() {
  group('bloc_transformers', () {
    test('debounceRestartable debounces rapid events and takes the latest', () {
      fakeAsync((async) {
        final controller = StreamController<String>();
        final results = <String>[];

        final transformer = debounceRestartable<String>(
          duration: const Duration(milliseconds: 50),
        );

        final transformedStream = transformer(
          controller.stream,
          (event) => Stream.value('processed-$event'),
        );

        final subscription = transformedStream.listen(results.add);

        // Emit multiple values within the debounce window
        controller.add('1');
        controller.add('2');
        controller.add('3');

        async.elapse(const Duration(milliseconds: 20));
        // Still within 50ms window: no event should be emitted yet
        expect(results, isEmpty);

        // Advance past debounce window
        async.elapse(const Duration(milliseconds: 40));
        expect(results, equals(['processed-3']));

        // Emit another item after debounce window
        controller.add('4');
        async.elapse(const Duration(milliseconds: 60));
        expect(results, equals(['processed-3', 'processed-4']));

        subscription.cancel();
        controller.close();
      });
    });

    test('debounceRestartable cancels previous in-flight handler when a newer event arrives', () {
      fakeAsync((async) {
        final controller = StreamController<String>();
        final results = <String>[];
        var isEvent1Cancelled = false;

        final transformer = debounceRestartable<String>(
          duration: const Duration(milliseconds: 30),
        );

        final transformedStream = transformer(
          controller.stream,
          (event) {
            final innerController = StreamController<String>(
              onCancel: () {
                if (event == '1') {
                  isEvent1Cancelled = true;
                }
              },
            );
            // Simulate work that takes time
            Timer(const Duration(milliseconds: 100), () {
              if (!innerController.isClosed) {
                innerController.add('finished-$event');
                innerController.close();
              }
            });
            return innerController.stream;
          },
        );

        final subscription = transformedStream.listen(results.add);

        // Send event 1
        controller.add('1');
        // Elapse past 30ms debounce so event 1 starts processing
        async.elapse(const Duration(milliseconds: 35));
        expect(isEvent1Cancelled, isFalse);
        expect(results, isEmpty);

        // Send event 2 before event 1 finishes (which takes 100ms)
        controller.add('2');
        // Elapse past event 2's 30ms debounce
        async.elapse(const Duration(milliseconds: 35));

        // Event 1's subscription should now be cancelled by restartable
        expect(isEvent1Cancelled, isTrue);

        subscription.cancel();
        controller.close();
      });
    });
  });
}

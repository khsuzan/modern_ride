import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';

/// Debounce helper with restartable transformer
EventTransformer<E> debounceRestartable<E>({
  Duration duration = const Duration(milliseconds: 500),
}) {
  return (events, mapper) =>
      restartable<E>()(events.debounce(duration), mapper);
}

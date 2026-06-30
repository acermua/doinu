// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audiohandler.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One provider to rule them all

@ProviderFor(audioHandler)
final audioHandlerProvider = AudioHandlerProvider._();

/// One provider to rule them all

final class AudioHandlerProvider
    extends
        $FunctionalProvider<
          AsyncValue<MyAudioHandler>,
          MyAudioHandler,
          FutureOr<MyAudioHandler>
        >
    with $FutureModifier<MyAudioHandler>, $FutureProvider<MyAudioHandler> {
  /// One provider to rule them all
  AudioHandlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'audioHandlerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$audioHandlerHash();

  @$internal
  @override
  $FutureProviderElement<MyAudioHandler> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MyAudioHandler> create(Ref ref) {
    return audioHandler(ref);
  }
}

String _$audioHandlerHash() => r'ed4d99f4073adb08edb62c76dc6717d6e129e238';

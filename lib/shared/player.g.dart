// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PlayerColour)
final playerColourProvider = PlayerColourProvider._();

final class PlayerColourProvider
    extends $NotifierProvider<PlayerColour, Color> {
  PlayerColourProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playerColourProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playerColourHash();

  @$internal
  @override
  PlayerColour create() => PlayerColour();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Color value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Color>(value),
    );
  }
}

String _$playerColourHash() => r'd14904842d19adc0b57224cfc8b5f5e7d8eeeded';

abstract class _$PlayerColour extends $Notifier<Color> {
  Color build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Color, Color>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Color, Color>,
              Color,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(connectedBluetoothDevice)
final connectedBluetoothDeviceProvider = ConnectedBluetoothDeviceProvider._();

final class ConnectedBluetoothDeviceProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  ConnectedBluetoothDeviceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectedBluetoothDeviceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectedBluetoothDeviceHash();

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    return connectedBluetoothDevice(ref);
  }
}

String _$connectedBluetoothDeviceHash() =>
    r'7adeca7bcae80a320b44757f77406d145816f1fd';

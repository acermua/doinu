// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supabase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(supabase)
final supabaseProvider = SupabaseProvider._();

final class SupabaseProvider
    extends $FunctionalProvider<SupabaseApi, SupabaseApi, SupabaseApi>
    with $Provider<SupabaseApi> {
  SupabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supabaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supabaseHash();

  @$internal
  @override
  $ProviderElement<SupabaseApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SupabaseApi create(Ref ref) {
    return supabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupabaseApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupabaseApi>(value),
    );
  }
}

String _$supabaseHash() => r'c1c05f77379461007975f2417f835d20fa2f8bbd';

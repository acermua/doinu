import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'SUPA_URL', obfuscate: true)
  static final String url = _Env.url;

  @EnviedField(varName: 'SUPA_KEY', obfuscate: true)
  static final String anonKey = _Env.anonKey;

  @EnviedField(varName: 'DONATION', obfuscate: true)
  static final String donation = _Env.donation;
}

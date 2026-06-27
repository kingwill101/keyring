import 'package:keyring_cli/keyring_cli.dart';

Future<void> main(List<String> arguments) async {
  final cli = KeyringCli();
  await cli.run(arguments);
}

import 'dart:convert';
import 'dart:io';

import 'package:appcast_generator/appcast_generator.dart';
import 'package:appcast_generator/src/file_handler.dart';
import 'package:args/command_runner.dart';
import 'package:cryptography/cryptography.dart';
import 'package:intl/intl.dart';

class CreateCommand extends Command {
  final name = "create";
  final description = "Creates a new Appcast file with only meta data. To add <items> use the command 'add'.";

  CreateCommand() {
    argParser
      ..addOption('appcast-file', abbr: 'f')
      ..addOption('title', abbr: 't')
      ..addOption('url', abbr: 'u')
      ..addOption('description', abbr: 'd')
      ..addOption('language', abbr: 'l', defaultsTo: 'en');
  }

  Future<void> run() async {
    if (argResults != null) {
      try {
        final String? path = argResults!['appcast-file'];
        final String? title = argResults!['title'];
        final String? url = argResults!['url'];
        final String? description = argResults!['description'];
        final String language = argResults!['language'];
        if (path == null) throw 'Please provide the name of the Appcast file to be created.';
        if (title == null) throw 'Please provide the title of the Appcast.';
        if (url == null) throw 'Please provide the link to the Appcast.';
        if (description == null) throw 'Please provide the description of the Appcast.';
        File file = File(path);
        if (!file.existsSync()) {
          print("Try to download $url");
          await FileHandler.download(url: url, path: path);
          return;
        }
        Appcast appcast = Appcast(
          meta: AppcastMeta(
            title: title,
            link: url,
            description: description,
            language: language,
          ),
          items: [],
        );
        final String? str = AppcastUtil.createXMLStringFromItems(appcast);
        if (str == null) throw 'An error occured creating your Appcast file.';
        await file.writeAsString(str);
      } catch (error) {
        print(error);
      }
    }
  }
}

class AddCommand extends Command {
  final name = "add";
  final description = "Adds a <item> element to an Appcast file. To create a new Appcast use 'create'.";

  AddCommand() {
    final DateFormat formatter = DateFormat('EEE, dd MMM yyyy hh:mm:ss +SSSS');
    argParser
      ..addOption('appcast-file', abbr: 'f')
      ..addOption('title', abbr: 't')
      ..addOption('release-notes-url', abbr: 'n')
      ..addOption('release-date', abbr: 'd', defaultsTo: formatter.format(DateTime.now()))
      ..addOption('file-url', abbr: 'u')
      ..addOption('operating-system', abbr: 'o')
      ..addOption('file')
      ..addOption('private-key-file', defaultsTo: 'private.key')
      ..addOption('public-key-file', defaultsTo: 'public.key')
      ..addOption('version', abbr: 'v');
  }

  Future<void> run() async {
    if (argResults != null) {
      final String? path = argResults!['appcast-file'];
      final String? title = argResults!['title'];
      final String? notes = argResults!['release-notes-url'];
      final String? url = argResults!['file-url'];
      final String? os = argResults!['operating-system'];
      final String? updateFile = argResults!['file'];
      final String? version = argResults!['version'];
      if (path == null) throw "There must be an input file. Use 'appcast-file' or 'f' and append the path to the inputfile.";
      if (title == null) throw 'Please provide a title for the new version.';
      if (notes == null) throw 'Please provide an url to the release notes for the new version.';
      if (url == null) throw 'Please provide a url where this update can be downloaded.';
      if (os == null) throw 'Please provide for which operatiing system this update is for.';
      if (updateFile == null) throw "Please provide the update file so that it can be signed and the content length can be calculated.";
      if (version == null) throw 'Please provide the version of this update.';

      // Generate a keypair.
      final Ed25519 algorithm = Ed25519();
      final SimpleKeyPair keyPair = await algorithm.newKeyPair();
      // Create key files
      final privateKeyFile = File(argResults!['private-key-file']);
      await privateKeyFile.writeAsString(base64Encode(await keyPair.extractPrivateKeyBytes()));
      final publicKeyFile = File(argResults!['public-key-file']);
      await publicKeyFile.writeAsString(base64Encode((await keyPair.extractPublicKey()).bytes));
      // Sign
      final Signature sign = await algorithm.sign(
        await File(updateFile).readAsBytes(),
        keyPair: keyPair,
      );

      int contentLength = File(updateFile).lengthSync();
      String signature = base64Encode(sign.bytes);

      File file = File(path);
      Appcast? appcast = AppcastUtil.parseAppcastItemsFromFile(file);
      if (appcast == null) throw 'An error occured parsing your input file.';
      appcast.items.add(
        AppcastItem(
          title: title,
          releaseNotesURL: notes,
          dateString: argResults!['release-date'],
          fileURL: url,
          osString: os,
          contentLength: contentLength,
          versionString: version,
          signature: signature,
        ),
      );
      String? str = AppcastUtil.createXMLStringFromItems(appcast);
      if (str == null) throw 'An error occured creating your updated Appcast file.';
      file.writeAsStringSync(str);
    }
  }
}

class UpdateCommand extends Command {
  final name = "update";
  final description = "Update the <item> element of a single item Appcast file. To create a new Appcast use 'create'.";

  UpdateCommand() {
    argParser
      ..addOption('input-file', abbr: 'f')
      ..addOption('title', abbr: 't')
      ..addOption('release-notes-url', abbr: 'n')
      ..addOption('release-date', abbr: 'd')
      ..addOption('file-url', abbr: 'u')
      ..addOption('operating-systems', abbr: 'o')
      ..addOption('content-length', abbr: 'l')
      ..addOption('version', abbr: 'v')
      ..addOption('signature', abbr: 's');
  }

  void run() {
    // if (argResults != null) {
    //   final String? file = argResults!['f'];
    //   if (file == null)
    //     throw "There must be an input file. Use 'input-file' or 'f' and append the path to the inputfile.";
    // }
  }
}

int main(List<String> arguments) {
  var exitCode = 0;
  var cr = CommandRunner('appcast_generator', 'appcast_generator generates Appcast files with certain user input as well as files.')
    ..addCommand(CreateCommand())
    ..addCommand(AddCommand())
    ..addCommand(UpdateCommand())
    ..run(arguments);
  return exitCode;
}

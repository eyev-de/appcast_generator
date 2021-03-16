import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:appcast_generator/appcast_generator.dart';
import 'package:intl/intl.dart';

void main() {
  test('Read and parse Appcast file', () {
    Appcast? appcast =
        AppcastUtil.parseAppcastItemsFromFile(File('./test/test_in.xml'));
    expect(appcast != null, true);
    expect(appcast!.items.isNotEmpty, true);
    expect(appcast.items[0].title, 'Version 1.0');
    expect(appcast.items[0].fileURL, 'https://eyev.de/dl/windows/Skyle.msi');
  });
  test('Generate Appcast file', () {
    final meta = AppcastMeta(
      title: 'Skyle Windows App',
      link: 'https://eyev.de/dl/windows/appcast.xml',
      description:
          'App to use the Skyle Eyetracker for Windows made by eyeV GmbH.',
    );
    final formatter = DateFormat('EEE, dd MMM yyyy hh:mm:ss +SSSS');
    final item = AppcastItem(
      title: 'Version 1.0',
      fileURL: 'https://eyev.de/dl/windows/Skyle.msi',
      releaseNotesURL: 'https://eyev.de/dl/windows/notes.md',
      versionString: '1.0',
      osString: 'windows',
      contentLength: 77777,
      dateString: formatter.format(DateTime.now()),
    );
    var str = AppcastUtil.createXMLStringFromItems(
      Appcast(
        meta: meta,
        items: [item],
      ),
    );
    expect(str != null, true);
    final file_out = File('./test/test_out.xml');
    file_out.writeAsStringSync(str!);
  });
}

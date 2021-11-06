import 'dart:io';

import 'package:http/http.dart' as http;

enum FileState { none, downloading, downloaded, uploading, uploaded, unzipped, failed }

class FileHandler {
  static Future<void> download({
    required String url,
    required String path,
    void Function(FileState)? state,
    void Function(double)? progress,
  }) async {
    try {
      final httpClient = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = httpClient.send(request);
      if (state != null) state(FileState.downloading);
      print(path);
      File file = File(path);
      if (file.existsSync()) file.deleteSync();
      file = await file.create();

      final List<int> chunks = [];
      int downloaded = 0;

      final rs = await response;
      await for (final chunk in rs.stream) {
        try {
          // Display percentage of completion
          if (rs.contentLength != null) {
            print(
              'downloadPercentage: ${downloaded / rs.contentLength! * 100}',
            );
            if (progress != null) progress(downloaded / rs.contentLength!);
          }
          downloaded += chunk.length;
          if (downloaded % 10000 == 0) {
            print('Downloaded ${downloaded / 1000} KB');
          }
          chunks.addAll(chunk);
        } catch (error) {
          print('Error in listen in download. $error');
        }
      }

      try {
        if (rs.contentLength != null) {
          print(
            'downloadPercentage: ${downloaded / rs.contentLength! * 100}',
          );
          if (progress != null) progress(downloaded / rs.contentLength!);
        }
        print('Finished download, downloading ${downloaded / 1000000} MB');
        // Save the file
        file = await file.writeAsBytes(chunks);
        if (state != null) state(FileState.downloaded);
      } catch (error) {
        print('Error onDone in download. $error');
      }
    } catch (error) {
      print('Error in download. $error');
    }
  }
}

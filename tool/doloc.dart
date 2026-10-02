import 'dart:convert';
import 'dart:io';

/// Atualiza traduções ARB via [doloc.io](https://doloc.io).
///
/// Uso:
/// ```bash
/// export API_TOKEN=seu_token
/// dart run tool/doloc.dart
/// ```
///
/// Fonte: `lib/l10n/app_pt.arb` (português).
/// Alvos: `en`, `ja`, `es`.
void main() async {
  const sourceFile = 'lib/l10n/app_pt.arb';
  const targets = [
    'lib/l10n/app_en.arb',
    'lib/l10n/app_ja.arb',
    'lib/l10n/app_es.arb',
  ];

  final apiToken = Platform.environment['API_TOKEN'];
  if (apiToken == null || apiToken.isEmpty) {
    stderr.writeln(
      'Error: provide API_TOKEN as environment variable!',
    );
    exit(1);
  }

  Future<void> updateFile(String targetFile) async {
    final boundary =
        '----dartFormBoundary${DateTime.now().millisecondsSinceEpoch}';

    final body = StringBuffer();
    void addFilePart(String name, String filePath) {
      body
        ..write('--$boundary\r\n')
        ..write(
          'Content-Disposition: form-data; name="$name"; '
          'filename="${filePath.split('/').last}"\r\n',
        )
        ..write('Content-Type: application/octet-stream\r\n\r\n')
        ..write(utf8.decode(File(filePath).readAsBytesSync()))
        ..write('\r\n');
    }

    addFilePart('source', sourceFile);
    addFilePart('target', targetFile);
    body.write('--$boundary--\r\n');

    final request = await HttpClient().postUrl(Uri.parse('https://api.doloc.io'))
      ..headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      )
      ..headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiToken')
      ..add(utf8.encode(body.toString()));

    final response = await request.close();
    final responseBytes =
        await response.fold<List<int>>([], (p, e) => p..addAll(e));
    File(targetFile).writeAsBytesSync(responseBytes);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      stdout.writeln('result written to $targetFile');
    } else {
      stderr.writeln('Request failed with status: ${response.statusCode}');
      stderr.writeln(utf8.decode(responseBytes));
      stderr.writeln(
        'The response was written to $targetFile. Inspect it, revert it '
        'from Git, fix the issue, and retry.',
      );
      exit(2);
    }
  }

  for (final target in targets) {
    await updateFile(target);
  }
}

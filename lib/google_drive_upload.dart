import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: [drive.DriveApi.driveFileScope],
);

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

Future<void> uploadPDFToDrive(File pdfFile, String fileName) async {
  final account = await _googleSignIn.signIn();
  final authHeaders = await account?.authHeaders;
  if (authHeaders == null) throw Exception('No se pudo autenticar con Google');
  final authenticateClient = GoogleAuthClient(authHeaders);

  final driveApi = drive.DriveApi(authenticateClient);

  var media = drive.Media(pdfFile.openRead(), pdfFile.lengthSync());
  var driveFile = drive.File();
  driveFile.name = fileName;

  await driveApi.files.create(driveFile, uploadMedia: media);
}
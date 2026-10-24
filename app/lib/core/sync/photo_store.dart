import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// One photo of a lot, kept on the phone.
class LocalPhoto {
  const LocalPhoto({
    required this.path,
    required this.sha256Hex,
    required this.thumbBase64,
  });

  /// Full photo (max 1280 px, JPEG quality 70) in the app's own folder.
  final String path;

  /// Fingerprint of the full photo, taken the moment it was captured.
  final String sha256Hex;

  /// 480 px, quality 60 thumbnail, uploaded to Firestore (PLAN.md §5
  /// fallback: Cloud Storage needs the paid Blaze plan since Feb 2026).
  final String thumbBase64;
}

/// Takes and stores photos. Uploading is Firestore's job: thumbnails are
/// written like any other record, so they wait offline and retry by
/// themselves when internet returns.
class PhotoStore {
  final _picker = ImagePicker();

  /// Opens the camera. Returns null if the user backed out.
  Future<LocalPhoto?> capture() async {
    final shot = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 70,
    );
    if (shot == null) return null;

    final dir = Directory(
      '${(await getApplicationDocumentsDirectory()).path}/photos',
    );
    await dir.create(recursive: true);
    final path = '${dir.path}/${const Uuid().v4()}.jpg';
    final bytes = await shot.readAsBytes();
    await File(path).writeAsBytes(bytes, flush: true);

    final thumb = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 480,
      minHeight: 480,
      quality: 60,
    );
    return LocalPhoto(
      path: path,
      sha256Hex: sha256.convert(bytes).toString(),
      thumbBase64: base64Encode(thumb),
    );
  }

  Future<void> delete(LocalPhoto photo) async {
    final f = File(photo.path);
    if (await f.exists()) await f.delete();
  }
}

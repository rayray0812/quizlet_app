import 'dart:typed_data';

class AdminComplianceArchive {
  final String fileName;
  final String mimeType;
  final Uint8List content;
  final String signature;
  final String checksumSha256;
  final int windowDays;
  final String format;

  const AdminComplianceArchive({
    required this.fileName,
    required this.mimeType,
    required this.content,
    required this.signature,
    required this.checksumSha256,
    required this.windowDays,
    required this.format,
  });
}

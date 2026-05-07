import 'dart:io';

class UploadDocument {
  int id;
  String name;
  File file;

  UploadDocument({
    required this.id,
    required this.name,
    required this.file,
  });
}
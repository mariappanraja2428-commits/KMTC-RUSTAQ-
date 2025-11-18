import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker_for_web/image_picker_for_web.dart';

class PhotoUpload extends StatefulWidget {
  final String title;
  final Function(Uint8List?) onPicked;
  final String? existingUrl;

  const PhotoUpload({required this.title, required this.onPicked, this.existingUrl, Key? key}) : super(key: key);

  @override
  State<PhotoUpload> createState() => _PhotoUploadState();
}

class _PhotoUploadState extends State<PhotoUpload> {
  Uint8List? _bytes;

  Future<void> pick() async {
    final bytes = await ImagePickerWeb.getImageAsBytes();
    if (bytes != null) {
      setState(() => _bytes = bytes);
      widget.onPicked(bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton(onPressed: pick, child: Text('Select ${widget.title}')),
        const SizedBox(width: 12),
        if (_bytes != null)
          SizedBox(width: 80, height: 80, child: Image.memory(_bytes!, fit: BoxFit.cover))
        else if (widget.existingUrl != null)
          SizedBox(width: 80, height: 80, child: Image.network(widget.existingUrl!, fit: BoxFit.cover))
        else
          const Text('No photo selected'),
      ],
    );
  }
}

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker_for_web/image_picker_for_web.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../widgets/photo_upload.dart';

class RecordFormPage extends StatefulWidget {
  final String? prefillArea;
  final String? recordId;
  const RecordFormPage({this.prefillArea, this.recordId, Key? key}) : super(key: key);

  @override
  State<RecordFormPage> createState() => _RecordFormPageState();
}

class _RecordFormPageState extends State<RecordFormPage> {
  final _formKey = GlobalKey<FormState>();
  String area = 'RUSTAQ EMERGENCY';
  String line = 'OHL';
  String size = 'LT';
  String material = 'Conductor';
  final meterCtrl = TextEditingController();
  final txCtrl = TextEditingController();
  final placeCtrl = TextEditingController();
  final latCtrl = TextEditingController();
  final lonCtrl = TextEditingController();
  Uint8List? beforeBytes;
  Uint8List? afterBytes;
  String? beforeUrl;
  String? afterUrl;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefillArea != null) area = widget.prefillArea!;
    if (widget.recordId != null) _loadExisting();
  }

  Future<void> _loadExisting() async {
    final doc = await FirebaseFirestore.instance.collection('records').doc(widget.recordId).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    setState(() {
      area = data['area'] ?? area;
      line = data['line'] ?? line;
      size = data['size'] ?? size;
      material = data['material'] ?? material;
      meterCtrl.text = data['meter'] ?? '';
      txCtrl.text = data['txNo'] ?? '';
      placeCtrl.text = data['place'] ?? '';
      beforeUrl = data['beforeUrl'];
      afterUrl = data['afterUrl'];
      latCtrl.text = (data['latitude'] ?? '').toString();
      lonCtrl.text = (data['longitude'] ?? '').toString();
    });
  }

  Future<void> pickImageAndSet(bool isBefore) async {
    final bytes = await ImagePickerWeb.getImageAsBytes();
    if (bytes == null) return;
    setState(() {
      if (isBefore) beforeBytes = bytes; else afterBytes = bytes;
    });
  }

  Future<String> _upload(Uint8List bytes, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putData(bytes);
    return ref.getDownloadURL();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      final id = widget.recordId ?? const Uuid().v4();
      String bUrl = beforeUrl ?? '';
      String aUrl = afterUrl ?? '';

      if (beforeBytes != null) {
        bUrl = await _upload(beforeBytes!, 'records/$id/before.jpg');
      }
      if (afterBytes != null) {
        aUrl = await _upload(afterBytes!, 'records/$id/after.jpg');
      }

      await FirebaseFirestore.instance.collection('records').doc(id).set({
        'area': area,
        'line': line,
        'size': size,
        'material': material,
        'meter': meterCtrl.text,
        'txNo': txCtrl.text,
        'place': placeCtrl.text,
        'beforeUrl': bUrl,
        'afterUrl': aUrl,
        'latitude': double.tryParse(latCtrl.text) ?? 0.0,
        'longitude': double.tryParse(lonCtrl.text) ?? 0.0,
        'deleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: \$e')));
    } finally {
      setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    meterCtrl.dispose();
    txCtrl.dispose();
    placeCtrl.dispose();
    latCtrl.dispose();
    lonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final areas = [
      'RUSTAQ EMERGENCY','HAZAM EMERGENCY','HOQAIN EMERGENCY','KHAFDI EMERGENCY','AWABI EMERGENCY',
      'RUSTAQ MAINTENANCES - 1','HAZAM MAINTENANCES - 2','RUSTAQ ASSET SECURITY - 1','HAZAM ASSET SECURITY - 1'
    ];

    return Scaffold(
      appBar: AppBar(title: Text(widget.recordId == null ? 'New Record' : 'Edit Record')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: area,
                items: areas.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                onChanged: (v) => setState(() => area = v!),
                decoration: const InputDecoration(labelText: 'Area'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: line,
                items: ['OHL','CABLE','MFP CLEARANCE'].map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                onChanged: (v) => setState(() => line = v!),
                decoration: const InputDecoration(labelText: 'Line'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: size,
                items: ['LT','11KVA','33KVA'].map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                onChanged: (v) => setState(() => size = v!),
                decoration: const InputDecoration(labelText: 'Size'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: material,
                items: ['Conductor','Cable','MFP','Foundation'].map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                onChanged: (v) => setState(() => material = v!),
                decoration: const InputDecoration(labelText: 'Material'),
              ),
              TextFormField(controller: meterCtrl, decoration: const InputDecoration(labelText: 'Meter (mtr)'), keyboardType: TextInputType.number),
              TextFormField(controller: txCtrl, decoration: const InputDecoration(labelText: 'TX No')),
              TextFormField(controller: placeCtrl, decoration: const InputDecoration(labelText: 'Place')),
              Row(children: [
                Expanded(child: TextFormField(controller: latCtrl, decoration: const InputDecoration(labelText: 'Latitude'))),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: lonCtrl, decoration: const InputDecoration(labelText: 'Longitude'))),
              ]),
              const SizedBox(height: 12),
              PhotoUpload(title: 'Before', onPicked: (b) => beforeBytes = b, existingUrl: beforeUrl),
              const SizedBox(height: 8),
              PhotoUpload(title: 'After', onPicked: (b) => afterBytes = b, existingUrl: afterUrl),
              const SizedBox(height: 18),
              saving ? const CircularProgressIndicator() : ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Save Record')),
            ],
          ),
        ),
      ),
    );
  }
}

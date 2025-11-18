import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class RecordFormPage extends StatefulWidget {
  final String? recordId; // if editing, pass id
  const RecordFormPage({this.recordId, Key? key}) : super(key: key);

  @override
  State<RecordFormPage> createState() => _RecordFormPageState();
}

class _RecordFormPageState extends State<RecordFormPage> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();
  Uint8List? beforeBytes;
  Uint8List? afterBytes;
  String? beforeUrl;
  String? afterUrl;
  bool _saving = false;

  // Form fields
  String area = 'RUSTAQ EMERGENCY';
  String line = 'OHL';
  String size = 'LT';
  String material = 'Conductor';
  final meterCtrl = TextEditingController();
  final txCtrl = TextEditingController();
  final placeCtrl = TextEditingController();
  final latCtrl = TextEditingController();
  final lonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
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

  Future<void> pickImage(bool isBefore) async {
    final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => isBefore ? beforeBytes = bytes : afterBytes = bytes);
  }

  Future<String> _uploadBytes(Uint8List bytes, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    final task = await ref.putData(bytes);
    return ref.getDownloadURL();
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final id = widget.recordId ?? const Uuid().v4();
      String beforeDownload = beforeUrl ?? '';
      String afterDownload = afterUrl ?? '';

      if (beforeBytes != null) {
        beforeDownload = await _uploadBytes(beforeBytes!, 'records/$id/before.jpg');
      }
      if (afterBytes != null) {
        afterDownload = await _uploadBytes(afterBytes!, 'records/$id/after.jpg');
      }

      final docRef = FirebaseFirestore.instance.collection('records').doc(id);
      await docRef.set({
        'area': area,
        'line': line,
        'size': size,
        'material': material,
        'meter': meterCtrl.text,
        'txNo': txCtrl.text,
        'place': placeCtrl.text,
        'beforeUrl': beforeDownload,
        'afterUrl': afterDownload,
        'latitude': double.tryParse(latCtrl.text) ?? 0.0,
        'longitude': double.tryParse(lonCtrl.text) ?? 0.0,
        'deleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record saved')));
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Save error: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Save failed')));
    } finally {
      setState(() => _saving = false);
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
    final lines = ['OHL','CABLE','MFP CLEARANCE'];
    final sizes = ['LT','11KVA','33KVA'];
    final materials = ['Conductor','Cable','MFP','Foundation'];

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
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: line,
                    items: lines.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                    onChanged: (v) => setState(() => line = v!),
                    decoration: const InputDecoration(labelText: 'Line'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: size,
                    items: sizes.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                    onChanged: (v) => setState(() => size = v!),
                    decoration: const InputDecoration(labelText: 'Size'),
                  ),
                ),
              ]),
              DropdownButtonFormField<String>(
                value: material,
                items: materials.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                onChanged: (v) => setState(() => material = v!),
                decoration: const InputDecoration(labelText: 'Material'),
              ),
              TextFormField(controller: meterCtrl, decoration: const InputDecoration(labelText: 'Meter (mtr)'), keyboardType: TextInputType.number),
              TextFormField(controller: txCtrl, decoration: const InputDecoration(labelText: 'TX No')),
              TextFormField(controller: placeCtrl, decoration: const InputDecoration(labelText: 'Place')),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextFormField(controller: latCtrl, decoration: const InputDecoration(labelText: 'Latitude'))),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: lonCtrl, decoration: const InputDecoration(labelText: 'Longitude'))),
              ]),
              const SizedBox(height: 6),
              ElevatedButton(
                onPressed: () {
                  // Quick helper: open Google Maps in a new tab to pick coordinate manually
                  final url = 'https://www.google.com/maps';
                  // using dart:html would be web-only; safe to open via launch or window.open
                  // we use window.open only on web:
                  // ignore: avoid_web_libraries_in_flutter
                  import 'dart:html' as html; // placed inline to remind — move to top if used
                },
                child: const Text('Open Google Maps to pick location'),
              ),
              const SizedBox(height: 12),

              // Photo pickers
              Row(
                children: [
                  ElevatedButton(onPressed: () => pickImage(true), child: const Text('Select Before Photo')),
                  const SizedBox(width: 8),
                  if (beforeBytes != null)
                    SizedBox(height: 80, width: 80, child: Image.memory(beforeBytes!, fit: BoxFit.cover))
                  else if (beforeUrl != null && beforeUrl!.isNotEmpty)
                    SizedBox(height: 80, width: 80, child: Image.network(beforeUrl!, fit: BoxFit.cover))
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton(onPressed: () => pickImage(false), child: const Text('Select After Photo')),
                  const SizedBox(width: 8),
                  if (afterBytes != null)
                    SizedBox(height: 80, width: 80, child: Image.memory(afterBytes!, fit: BoxFit.cover))
                  else if (afterUrl != null && afterUrl!.isNotEmpty)
                    SizedBox(height: 80, width: 80, child: Image.network(afterUrl!, fit: BoxFit.cover))
                ],
              ),

              const SizedBox(height: 20),
              _saving
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _saveRecord,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Record'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

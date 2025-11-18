import 'package:flutter/material.dart';
import '../widgets/photo_upload.dart';
import 'records_page.dart';

class DataEntryPage extends StatefulWidget {
  final String selectedArea;

  const DataEntryPage({required this.selectedArea});

  @override
  State<DataEntryPage> createState() => _DataEntryPageState();
}

class _DataEntryPageState extends State<DataEntryPage> {
  String? line;
  String? size;
  String? material;
  String? cableOption;
  String? ohlOption;
  String? mfpOption;
  final TextEditingController meterController = TextEditingController();
  final TextEditingController txController = TextEditingController();
  final TextEditingController placeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.selectedArea)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Line'),
              items: ['OHL', 'CABLE', 'MFP CLEARANCE'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => line = val),
            ),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Size'),
              items: ['LT', '11KVA', '33KVA'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => size = val),
            ),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Material'),
              items: ['Conductor', 'Cable', 'MFP', 'Foundation'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => material = val),
            ),
            TextFormField(controller: meterController, decoration: InputDecoration(labelText: 'Meter (mtr)')),
            TextFormField(controller: txController, decoration: InputDecoration(labelText: 'TX No')),
            TextFormField(controller: placeController, decoration: InputDecoration(labelText: 'Place')),
            SizedBox(height: 20),
            PhotoUpload(title: 'Before Photo'),
            SizedBox(height: 10),
            PhotoUpload(title: 'After Photo'),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => RecordsPage()));
                },
                child: Text('Submit & Go to Records'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

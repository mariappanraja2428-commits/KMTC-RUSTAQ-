import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class Record {
  final String area;
  final String line;
  final String size;
  final String material;
  final String meter;
  final String txNo;
  final String place;
  final String beforePhotoUrl;
  final String afterPhotoUrl;
  final double latitude;
  final double longitude;

  Record({
    required this.area,
    required this.line,
    required this.size,
    required this.material,
    required this.meter,
    required this.txNo,
    required this.place,
    required this.beforePhotoUrl,
    required this.afterPhotoUrl,
    required this.latitude,
    required this.longitude,
  });
}

class RecordsPage extends StatefulWidget {
  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  List<Record> records = [
    Record(
      area: 'RUSTAQ EMERGENCY',
      line: 'OHL',
      size: 'LT',
      material: 'Conductor',
      meter: '15',
      txNo: '1411',
      place: 'RUSTAQ SOUQ',
      beforePhotoUrl: 'assets/before_sample.jpg',
      afterPhotoUrl: 'assets/after_sample.jpg',
      latitude: 23.5894,
      longitude: 57.9458,
    ),
    Record(
      area: 'HAZAM EMERGENCY',
      line: 'CABLE',
      size: '11KVA',
      material: 'Cable',
      meter: '20',
      txNo: '1412',
      place: 'HAZAM PLACE',
      beforePhotoUrl: 'assets/before_sample.jpg',
      afterPhotoUrl: 'assets/after_sample.jpg',
      latitude: 23.6000,
      longitude: 57.9200,
    ),
  ];

  // ---------------- Excel download ----------------
  void downloadExcel() {
    final workbook = xls.Workbook();
    final sheet = workbook.worksheets[0];
    final headers = [
      'Area',
      'Line',
      'Size',
      'Material',
      'Meter',
      'TX No',
      'Place',
      'Before Photo',
      'After Photo',
      'Latitude',
      'Longitude'
    ];
    for (int i = 0; i < headers.length; i++) {
      sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
    }

    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      sheet.getRangeByIndex(i + 2, 1).setText(r.area);
      sheet.getRangeByIndex(i + 2, 2).setText(r.line);
      sheet.getRangeByIndex(i + 2, 3).setText(r.size);
      sheet.getRangeByIndex(i + 2, 4).setText(r.material);
      sheet.getRangeByIndex(i + 2, 5).setText(r.meter);
      sheet.getRangeByIndex(i + 2, 6).setText(r.txNo);
      sheet.getRangeByIndex(i + 2, 7).setText(r.place);
      sheet.getRangeByIndex(i + 2, 8).setText(r.beforePhotoUrl);
      sheet.getRangeByIndex(i + 2, 9).setText(r.afterPhotoUrl);
      sheet.getRangeByIndex(i + 2, 10).setText(r.latitude.toString());
      sheet.getRangeByIndex(i + 2, 11).setText(r.longitude.toString());
    }

    final bytes = workbook.saveAsStream();
    workbook.dispose();
    final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)..setAttribute('download', 'records.xlsx')..click();
    html.Url.revokeObjectUrl(url);
  }

  // ---------------- PDF download ----------------
  void downloadPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text(
                'NAMA ELECTRICITY DISTRIBUTION COMPANY RUSTAQ',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: [
                  'Area',
                  'Line',
                  'Size',
                  'Material',
                  'Meter',
                  'TX No',
                  'Place',
                  'Before Photo',
                  'After Photo',
                  'Latitude',
                  'Longitude'
                ],
                data: records
                    .map((r) => [
                          r.area,
                          r.line,
                          r.size,
                          r.material,
                          r.meter,
                          r.txNo,
                          r.place,
                          r.beforePhotoUrl,
                          r.afterPhotoUrl,
                          r.latitude.toString(),
                          r.longitude.toString()
                        ])
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)..setAttribute('download', 'records.pdf')..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final teams = records.map((r) => r.area).toSet().toList();

    return Scaffold(
      appBar: AppBar(title: Text('Records')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton(onPressed: downloadExcel, child: Text('Download Excel')),
                SizedBox(width: 20),
                ElevatedButton(onPressed: downloadPDF, child: Text('Download PDF')),
              ],
            ),
            SizedBox(height: 20),
            ...teams.map((team) {
              final teamRecords = records.where((r) => r.area == team).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(team, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  DataTable(
                    columns: const [
                      DataColumn(label: Text('Line')),
                      DataColumn(label: Text('Size')),
                      DataColumn(label: Text('Material')),
                      DataColumn(label: Text('Meter')),
                      DataColumn(label: Text('TX No')),
                      DataColumn(label: Text('Place')),
                      DataColumn(label: Text('Before Photo')),
                      DataColumn(label: Text('After Photo')),
                      DataColumn(label: Text('Map')),
                    ],
                    rows: teamRecords.map((r) {
                      return DataRow(cells: [
                        DataCell(Text(r.line)),
                        DataCell(Text(r.size)),
                        DataCell(Text(r.material)),
                        DataCell(Text(r.meter)),
                        DataCell(Text(r.txNo)),
                        DataCell(Text(r.place)),
                        DataCell(Image.network(r.beforePhotoUrl, width: 60, height: 60)),
                        DataCell(Image.network(r.afterPhotoUrl, width: 60, height: 60)),
                        DataCell(IconButton(
                          icon: Icon(Icons.map),
                          onPressed: () {
                            final mapUrl =
                                'https://www.google.com/maps?q=${r.latitude},${r.longitude}';
                            html.window.open(mapUrl, '_blank');
                          },
                        )),
                      ]);
                    }).toList(),
                  ),
                  SizedBox(height: 30),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

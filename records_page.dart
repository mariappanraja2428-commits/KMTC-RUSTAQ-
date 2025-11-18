import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:html' as html;

class Record {
  final String area;
  final String line;
  final String size;
  final String material;
  final String meter;
  final String txNo;
  final String place;
  final String beforePhoto;
  final String afterPhoto;

  Record({
    required this.area,
    required this.line,
    required this.size,
    required this.material,
    required this.meter,
    required this.txNo,
    required this.place,
    required this.beforePhoto,
    required this.afterPhoto,
  });
}

class RecordsPage extends StatefulWidget {
  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  // Mock data, replace with actual saved records
  List<Record> records = [
    Record(
        area: 'RUSTAQ EMERGENCY',
        line: 'OHL',
        size: 'LT',
        material: 'Conductor',
        meter: '15',
        txNo: '1411',
        place: 'RUSTAQ SOUQ',
        beforePhoto: 'Before.jpg',
        afterPhoto: 'After.jpg'),
    Record(
        area: 'HAZAM EMERGENCY',
        line: 'CABLE',
        size: '11KVA',
        material: 'Cable',
        meter: '20',
        txNo: '1412',
        place: 'HAZAM PLACE',
        beforePhoto: 'Before.jpg',
        afterPhoto: 'After.jpg'),
  ];

  void downloadExcel() {
    final workbook = xls.Workbook();
    final sheet = workbook.worksheets[0];

    // Header row
    sheet.getRangeByName('A1').setText('Area');
    sheet.getRangeByName('B1').setText('Line');
    sheet.getRangeByName('C1').setText('Size');
    sheet.getRangeByName('D1').setText('Material');
    sheet.getRangeByName('E1').setText('Meter');
    sheet.getRangeByName('F1').setText('TX No');
    sheet.getRangeByName('G1').setText('Place');
    sheet.getRangeByName('H1').setText('Before Photo');
    sheet.getRangeByName('I1').setText('After Photo');

    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      sheet.getRangeByIndex(i + 2, 1).setText(r.area);
      sheet.getRangeByIndex(i + 2, 2).setText(r.line);
      sheet.getRangeByIndex(i + 2, 3).setText(r.size);
      sheet.getRangeByIndex(i + 2, 4).setText(r.material);
      sheet.getRangeByIndex(i + 2, 5).setText(r.meter);
      sheet.getRangeByIndex(i + 2, 6).setText(r.txNo);
      sheet.getRangeByIndex(i + 2, 7).setText(r.place);
      sheet.getRangeByIndex(i + 2, 8).setText(r.beforePhoto);
      sheet.getRangeByIndex(i + 2, 9).setText(r.afterPhoto);
    }

    final bytes = workbook.saveAsStream();
    workbook.dispose();

    final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'records.xlsx')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void downloadPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
              children: [
                pw.Text('NAMA ELECTRICITY DISTRIBUTION COMPANY RUSTAQ', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  headers: ['Area', 'Line', 'Size', 'Material', 'Meter', 'TX No', 'Place', 'Before Photo', 'After Photo'],
                  data: records.map((r) => [
                    r.area,
                    r.line,
                    r.size,
                    r.material,
                    r.meter,
                    r.txNo,
                    r.place,
                    r.beforePhoto,
                    r.afterPhoto
                  ]).toList(),
                ),
              ]
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'records.pdf')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final teams = records.map((e) => e.area).toSet().toList();

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
                    ],
                    rows: teamRecords.map((r) {
                      return DataRow(cells: [
                        DataCell(Text(r.line)),
                        DataCell(Text(r.size)),
                        DataCell(Text(r.material)),
                        DataCell(Text(r.meter)),
                        DataCell(Text(r.txNo)),
                        DataCell(Text(r.place)),
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

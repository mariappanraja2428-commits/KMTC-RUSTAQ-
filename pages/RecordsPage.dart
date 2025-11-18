// inside RecordsPage build()
Row(
  children: [
    ElevatedButton(
      onPressed: () async {
        final snapshot = await FirebaseFirestore.instance
            .collection('records')
            .where('deleted', isEqualTo: false)
            .orderBy('createdAt', descending: true)
            .get();
        await exportRecordsToExcel(snapshot.docs, fileName: 'NAMA_records_${DateTime.now().toIso8601String()}.xlsx');
      },
      child: Text('Export Excel'),
    ),
    SizedBox(width: 12),
    ElevatedButton(
      onPressed: () async {
        final snapshot = await FirebaseFirestore.instance
            .collection('records')
            .where('deleted', isEqualTo: false)
            .orderBy('createdAt', descending: true)
            .get();

        // optional background image url (host your background image publicly)
        final bgUrl = 'https://your-public-host/backgrounds/nama_pdf_bg.png';
        await exportRecordsToPdf(snapshot.docs,
            fileName: 'NAMA_records_${DateTime.now().toIso8601String()}.pdf',
            bgImageUrl: bgUrl,
            embedThumbnails: true);
      },
      child: Text('Export PDF'),
    ),
  ],
)

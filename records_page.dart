import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'record_form_page.dart';
import 'package:firebase_storage/firebase_storage.dart';

class RecordsPage extends StatefulWidget {
  const RecordsPage({Key? key}) : super(key: key);

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  bool showOnlyActive = true;

  Stream<QuerySnapshot> _recordsStream() {
    if (showOnlyActive) {
      return FirebaseFirestore.instance.collection('records').where('deleted', isEqualTo: false).orderBy('createdAt', descending: true).snapshots();
    } else {
      return FirebaseFirestore.instance.collection('records').orderBy('createdAt', descending: true).snapshots();
    }
  }

  Future<void> _softDelete(String id) async {
    await FirebaseFirestore.instance.collection('records').doc(id).update({'deleted': true});
  }

  Future<void> _restore(String id) async {
    await FirebaseFirestore.instance.collection('records').doc(id).update({'deleted': false});
  }

  Future<void> _permanentDelete(String id, String? beforeUrl, String? afterUrl) async {
    try {
      if (beforeUrl != null && beforeUrl.isNotEmpty) {
        await FirebaseStorage.instance.refFromURL(beforeUrl).delete();
      }
      if (afterUrl != null && afterUrl.isNotEmpty) {
        await FirebaseStorage.instance.refFromURL(afterUrl).delete();
      }
    } catch (e) {
      debugPrint('Storage delete failed: \$e');
    }
    await FirebaseFirestore.instance.collection('records').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Records'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecordFormPage())),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('New', style: TextStyle(color: Colors.white)),
          ),
          IconButton(
            icon: Icon(showOnlyActive ? Icons.delete_outline : Icons.list),
            tooltip: showOnlyActive ? 'Show all (including deleted)' : 'Show active only',
            onPressed: () => setState(() => showOnlyActive = !showOnlyActive),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _recordsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          final grouped = <String, List<QueryDocumentSnapshot>>{};
          for (final d in docs) {
            final area = d['area'] ?? 'Unknown';
            grouped.putIfAbsent(area, () => []).add(d);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: grouped.entries.map((entry) {
              return ExpansionTile(
                title: Text('${entry.key} (${entry.value.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                children: entry.value.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final deleted = data['deleted'] ?? false;
                  return Card(
                    color: deleted ? Colors.grey[200] : null,
                    child: ListTile(
                      leading: data['beforeUrl'] != null && data['beforeUrl'] != ''
                          ? Image.network(data['beforeUrl'], width: 56, height: 56, fit: BoxFit.cover)
                          : const SizedBox(width: 56, height: 56, child: Icon(Icons.image)),
                      title: Text('${data['line'] ?? ''} • ${data['size'] ?? ''}'),
                      subtitle: Text('${data['place'] ?? ''} • TX:${data['txNo'] ?? ''}'),
                      trailing: Wrap(
                        spacing: 6,
                        children: [
                          IconButton(
                            tooltip: 'Open map',
                            icon: const Icon(Icons.map),
                            onPressed: () {
                              final lat = (data['latitude'] ?? 0).toString();
                              final lon = (data['longitude'] ?? 0).toString();
                              final url = 'https://www.google.com/maps?q=$lat,$lon';
                              html.window.open(url, '_blank');
                            },
                          ),
                          IconButton(
                            tooltip: 'Edit',
                            icon: const Icon(Icons.edit),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecordFormPage(recordId: doc.id))),
                          ),
                          if (!deleted)
                            IconButton(
                              tooltip: 'Delete (move to trash)',
                              icon: const Icon(Icons.delete),
                              onPressed: () => _softDelete(doc.id),
                            )
                          else
                            IconButton(
                              tooltip: 'Restore',
                              icon: const Icon(Icons.restore_from_trash),
                              onPressed: () => _restore(doc.id),
                            ),
                          IconButton(
                            tooltip: 'View After',
                            icon: const Icon(Icons.image_outlined),
                            onPressed: () {
                              final after = data['afterUrl'] ?? '';
                              if (after.isNotEmpty) html.window.open(after, '_blank');
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

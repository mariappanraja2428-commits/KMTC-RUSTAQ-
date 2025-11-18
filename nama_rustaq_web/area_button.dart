import 'package:flutter/material.dart';
import '../pages/data_entry_page.dart';

class AreaButton extends StatelessWidget {
  final String areaName;

  const AreaButton({required this.areaName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DataEntryPage(selectedArea: areaName)),
          );
        },
        child: Text(areaName),
        style: ElevatedButton.styleFrom(
          minimumSize: Size(250, 50),
          textStyle: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

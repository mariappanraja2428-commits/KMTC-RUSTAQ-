import 'package:flutter/material.dart';
import '../pages/record_form_page.dart';

class AreaButton extends StatelessWidget {
  final String areaName;
  const AreaButton({required this.areaName, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RecordFormPage(prefillArea: areaName)),
            );
          },
          child: Text(areaName),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(300, 52),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

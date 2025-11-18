import 'package:flutter/material.dart';
import 'data_entry_page.dart';
import '../widgets/area_button.dart';

class LandingPage extends StatelessWidget {
  final List<String> areas = [
    'RUSTAQ EMERGENCY',
    'HAZAM EMERGENCY',
    'HOQAIN EMERGENCY',
    'KHAFDI EMERGENCY',
    'AWABI EMERGENCY',
    'RUSTAQ MAINTENANCES - 1',
    'HAZAM MAINTENANCES - 2',
    'RUSTAQ ASSET SECURITY - 1',
    'HAZAM ASSET SECURITY - 1',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 40),
              Text(
                'NAMA ELECTRICITY DISTRIBUTION COMPANY RUSTAQ',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Image.asset('assets/artboard2_375a155e-6ed9-4735-812e-7bc9f5a6639f.png', height: 120),
              SizedBox(height: 40),
              ...areas.map((area) => AreaButton(areaName: area)).toList(),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset('assets/nama_curve_067c25a7-7f31-4e80-b49a-9ef4f4209ca1.png', fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }
}

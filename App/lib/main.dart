import 'package:flutter/material.dart';

void main() => runApp(PetCareApp());

class PetCareApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetCare',
      home: Scaffold(
        appBar: AppBar(title: Text('PetCare')),
        body: Center(child: Text('Bem-vindo ao PetCare')),
      ),
    );
  }
}

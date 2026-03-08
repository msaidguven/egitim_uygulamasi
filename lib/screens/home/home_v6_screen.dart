import 'package:egitim_uygulamasi/models/profile_model.dart';
import 'package:flutter/material.dart';

class HomeV6Screen extends StatelessWidget {
  final Profile? profile;

  const HomeV6Screen({super.key, this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ana Sayfa V6')),
      body: Center(
        child: Text(
          'Home V6 test ekranı',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

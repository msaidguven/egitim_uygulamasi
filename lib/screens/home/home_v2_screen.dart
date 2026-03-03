import 'package:egitim_uygulamasi/models/profile_model.dart';
import 'package:egitim_uygulamasi/screens/home/map/screens/class_map_screen.dart';
import 'package:flutter/material.dart';

class HomeV2Screen extends StatelessWidget {
  const HomeV2Screen({super.key, this.profile});

  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    return ClassMapScreen(profile: profile);
  }
}

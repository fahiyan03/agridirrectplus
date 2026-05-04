import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../farmer/farmer_public_profile_screen.dart';

// Buyer যখন কৃষকের profile দেখে তখন এই screen দেখায়
// FarmerPublicProfileScreen কে wrap করে extra actions যোগ করে
class FarmerProfileViewScreen extends StatelessWidget {
  final String farmerId;
  const FarmerProfileViewScreen({super.key, required this.farmerId});

  @override
  Widget build(BuildContext context) {
    return FarmerPublicProfileScreen(farmerId: farmerId);
  }
}
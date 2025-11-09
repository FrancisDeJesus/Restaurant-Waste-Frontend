import 'dart:convert';
import '../api_service.dart';
import '../../models/donations/donation_model.dart';

class DonationsApi {
  static const String drivePath = "donation_drive/";
  static const String donationPath = "donations/";

  // 🔹 Get all active donation drives
  static Future<List<DonationDrive>> getAllDrives() async {
    final response = await ApiService.get(drivePath);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => DonationDrive.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch donation drives");
    }
  }

  // 🔹 Donate collected trash to a drive
  static Future<void> donateTrash(int driveId, int pickupId) async {
    final response = await ApiService.post("${donationPath}donate/", {
      "drive_id": driveId,
      "pickup_id": pickupId,
    });
    if (response.statusCode != 201) {
      throw Exception("Failed to donate trash: ${response.body}");
    }
  }

  // 🔹 Get donation history
  static Future<List<Donation>> getHistory() async {
    final response = await ApiService.get("${donationPath}history/");
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Donation.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch donation history");
    }
  }

  // 🔹 Get total trash donated (for “Total Contributions”)
  static Future<double> getTotalDonated() async {
    final response = await ApiService.get("${donationPath}total/");
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['total_donated'] as num?)?.toDouble() ?? 0.0;
    } else {
      throw Exception("Failed to fetch total donated trash");
    }
  }
}

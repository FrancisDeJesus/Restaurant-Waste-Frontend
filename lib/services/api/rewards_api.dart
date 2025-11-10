import 'dart:convert';
import '../api_service.dart';
import '../../models/rewards/reward_model.dart';
import '../../models/rewards/reward_redemption_model.dart';

class RewardsApi {
  // =========================================================
  // 🎁 Get all available rewards
  // =========================================================
  static Future<List<Reward>> getAll() async {
    final response = await ApiService.get("rewards/");
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Reward.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch rewards: ${response.body}");
    }
  }

  // =========================================================
  // 💰 Get current user’s reward points summary
  // Matches: /api/rewards/points/
  // =========================================================
  static Future<Map<String, dynamic>> getUserPoints() async {
    final response = await ApiService.get("rewards/points/");
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'total_points': data['total_points'] ?? 0,
        'history': data['history'] ?? [],
      };
    } else {
      throw Exception("Failed to fetch reward points: ${response.body}");
    }
  }

  // =========================================================
  // 🪙 Redeem a reward
  // Matches: /api/rewards/{id}/redeem/
  // =========================================================
  static Future<bool> redeemReward(int rewardId) async {
    final response = await ApiService.post("rewards/$rewardId/redeem/", {});
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      throw Exception("Failed to redeem reward: ${response.body}");
    }
  }

  // =========================================================
  // 📜 Get redemption history
  // Matches: /api/rewards/redemptions/
  // =========================================================
  static Future<List<RewardRedemption>> getHistory() async {
    final response = await ApiService.get("rewards/redemptions/");
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => RewardRedemption.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch redemption history: ${response.body}");
    }
  }
}

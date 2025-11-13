import 'dart:convert';
import '../../models/rewards/redeemed_history_model.dart';
import '../api_service.dart';
import '../../models/rewards/reward_model.dart';
import '../../models/rewards/reward_redemption_model.dart';

class RewardsApi {

  // 🎁 Get all available rewards
  static Future<List<Reward>> getAll() async {
    final response = await ApiService.get("rewards/rewards/");
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Reward.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch rewards: ${response.body}");
    }
  }

  // 💰 Get user's points
  static Future<Map<String, dynamic>> getUserPoints() async {
    final response = await ApiService.get("rewards/rewards/points/");
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

  // 🪙 Redeem a reward
  static Future<bool> redeemReward(int rewardId) async {
    final response = await ApiService.post("rewards/rewards/$rewardId/redeem/", {});
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      throw Exception("Failed to redeem reward: ${response.body}");
    }
  }

  // 📜 Get redemption history (RewardRedemption)
  static Future<List<RewardRedemption>> getHistory() async {
    final response = await ApiService.get("rewards/rewards/redemptions/");
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => RewardRedemption.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch redemption history: ${response.body}");
    }
  }

  // 🧾 Get redeemed history (RedeemedHistory)
  static Future<List<RedeemedHistory>> getRedeemedHistory() async {
    final response = await ApiService.get("rewards/redeemed/");
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => RedeemedHistory.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load redeemed history: ${response.body}");
    }
  }
}

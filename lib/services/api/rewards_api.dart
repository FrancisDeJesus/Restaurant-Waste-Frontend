import 'dart:convert';
import '../api_service.dart';
import '../../models/rewards/reward_model.dart';
import '../../models/rewards/reward_redemption_model.dart';

class RewardsApi {
  static const String basePath = "rewards/";

  static Future<List<Reward>> getAll() async {
    final response = await ApiService.get(basePath);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Reward.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch rewards");
    }
  }

  static Future<void> redeemReward(int rewardId) async {
    final response = await ApiService.post("redeem/redeem/", {
      "reward_id": rewardId,
    });
    if (response.statusCode != 201) {
      throw Exception("Failed to redeem reward: ${response.body}");
    }
  }

  static Future<List<RewardRedemption>> getHistory() async {
    final response = await ApiService.get("redeem/history/");
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => RewardRedemption.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch redemption history");
    }
  }
}

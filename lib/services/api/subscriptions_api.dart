// lib/services/api/subscriptions_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import '../../models/subscriptions/subscription_model.dart';

class SubscriptionsApi {
  static const String _endpoint = "subscriptions/";

  static Future<List<SubscriptionPlan>> getPlans() async {
    final response = await ApiService.get("${_endpoint}plans/");
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((json) => SubscriptionPlan.fromJson(json)).toList();
    } else {
      throw Exception("Failed to fetch plans: ${response.body}");
    }
  }

  static Future<Subscription?> getActiveSubscription() async {
    final response = await ApiService.get("${_endpoint}manage/active/");
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Subscription.fromJson(data);
    }
    return null;
  }

  static Future<List<Subscription>> getHistory() async {
    final response = await ApiService.get("${_endpoint}manage/history/");
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((json) => Subscription.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load history: ${response.body}");
    }
  }

  static Future<bool> subscribeToPlan(int planId, {String method = "GCash"}) async {
    final body = {"plan_id": planId, "payment_method": method};
    final response = await ApiService.post("${_endpoint}manage/subscribe/", body);
    return response.statusCode == 201;
  }
}

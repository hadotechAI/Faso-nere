// lib/services/leaderboard_service.dart
import 'api_client.dart';

class LeaderboardService {
  LeaderboardService._();
  static final LeaderboardService instance = LeaderboardService._();

  Future<Map<String, dynamic>> getLeaderboard({String? period, String? lot}) async {
    final params = <String>[];
    if (period != null) params.add('period=$period');
    if (lot    != null) params.add('lot=${Uri.encodeComponent(lot)}');
    final query = params.isEmpty ? '' : '?${params.join('&')}';
    return api.get('/leaderboard$query');
  }

  Future<Map<String, dynamic>> getMyRank() async {
    return api.get('/leaderboard/my-rank');
  }
}

final leaderboardService = LeaderboardService.instance;

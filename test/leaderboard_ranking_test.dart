import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mathquest/services/leaderboard_service.dart';

void main() {
  test('leaderboard order includes zero scores and breaks ties by uid', () {
    final entries = LeaderboardService.sortEntries(const [
      LeaderboardEntry(uid: 'z-user', displayName: 'Zero Z', totalScore: 0),
      LeaderboardEntry(uid: 'b-user', displayName: 'Tie B', totalScore: 20),
      LeaderboardEntry(uid: 'a-user', displayName: 'Tie A', totalScore: 20),
      LeaderboardEntry(uid: 'a-zero', displayName: 'Zero A', totalScore: 0),
    ]);

    expect(
      entries.map((entry) => entry.uid).toList(),
      ['a-user', 'b-user', 'a-zero', 'z-user'],
    );
    expect(
      List<int>.generate(entries.length, (index) => index + 1),
      [1, 2, 3, 4],
    );
    expect(entries.skip(2).every((entry) => entry.totalScore == 0), isTrue);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

/// The free tier's daily quota, as the app receives it. The rule itself lives on
/// the server; what has to be right here is not inventing a cap the server did not
/// send — a wrong `cardCap` either locks paid-up content or gives the course away.
/// See `hddhistory-api/plans/260812-daily-keypoint-quota/README.md`.
void main() {
  group('KeypointAccessModel', () {
    test('carries a real cap through', () {
      final model = KeypointAccessModel.fromJson({
        'cardCap': 2,
        'reason': 'quota_spent',
        'quota': {'limit': 1, 'used': 1, 'remaining': 0, 'claimedKeypointId': 'kp-1'},
      });

      final entity = model.toEntity();

      expect(entity.cardCap, 2);
      expect(entity.reason, KeypointAccessReason.quotaSpent);
      expect(entity.quota?.remaining, 0);
      expect(entity.quota?.claimedKeypointId, 'kp-1');
    });

    /// `null` means no limit and `0` means nothing readable — two different
    /// answers, so the field must not default to either.
    test('keeps null cap distinct from a zero cap', () {
      expect(
        KeypointAccessModel.fromJson({'cardCap': null, 'reason': 'premium'}).toEntity().cardCap,
        isNull,
      );
      expect(
        KeypointAccessModel.fromJson({'cardCap': 0, 'reason': 'quota_spent'}).toEntity().cardCap,
        0,
      );
    });

    /// A response from an API that predates the quota, or a reason added later.
    /// `unknown` is what the shell checks before letting the quota bound anything,
    /// so this mapping is what keeps an old API from producing a wall.
    test('maps an unrecognised or missing reason to unknown', () {
      expect(KeypointAccessModel.fromJson(<String, dynamic>{}).toEntity().reason, KeypointAccessReason.unknown);
      expect(
        KeypointAccessModel.fromJson({'reason': 'something_new'}).toEntity().reason,
        KeypointAccessReason.unknown,
      );
    });

    test('maps every reason the server can send', () {
      const wire = {
        'quota_disabled': KeypointAccessReason.quotaDisabled,
        'premium': KeypointAccessReason.premium,
        'already_completed': KeypointAccessReason.alreadyCompleted,
        'todays_free_keypoint': KeypointAccessReason.todaysFreeKeypoint,
        'ticket_available': KeypointAccessReason.ticketAvailable,
        'quota_spent': KeypointAccessReason.quotaSpent,
      };

      wire.forEach((value, expected) {
        expect(KeypointAccessReason.fromWire(value), expected, reason: value);
      });
    });
  });

  group('KeypointClaimModel', () {
    test('reads a granted claim, which lifts the cap', () {
      final claim = KeypointClaimModel.fromJson({
        'granted': true,
        'cardCap': null,
        'reason': 'todays_free_keypoint',
        'claimedKeypointId': 'kp-1',
      }).toEntity();

      expect(claim.granted, isTrue);
      expect(claim.cardCap, isNull);
      expect(claim.reason, KeypointAccessReason.todaysFreeKeypoint);
    });

    test('reads a refusal, which keeps the wall and names the holder', () {
      final claim = KeypointClaimModel.fromJson({
        'granted': false,
        'cardCap': 2,
        'reason': 'quota_spent',
        'claimedKeypointId': 'kp-other',
      }).toEntity();

      expect(claim.granted, isFalse);
      expect(claim.cardCap, 2);
      expect(claim.claimedKeypointId, 'kp-other');
    });

    /// A failed request must never read as granted — the repository's own default
    /// says so too, and this pins the shape.
    test('defaults to refused', () {
      expect(KeypointClaimModel.fromJson(<String, dynamic>{}).toEntity().granted, isFalse);
    });
  });
}

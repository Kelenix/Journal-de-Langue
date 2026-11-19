import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../domain/billing_repository.dart';
import '../domain/subscription.dart';

class SupabaseSubscriptionRepository implements SubscriptionRepository {
  const SupabaseSubscriptionRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Subscription?> current() => guardFailures(() async {
    // La RLS ne laisse voir que l'abonnement de l'utilisateur connecté.
    final row = await _client
        .from('subscriptions')
        .select('plan, expires_at, in_trial')
        .maybeSingle();
    return row == null ? null : Subscription.fromJson(row);
  });
}

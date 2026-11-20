import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../domain/ad_status.dart';
import '../domain/ads_service.dart';

class SupabaseAdsRepository implements AdsRepository {
  const SupabaseAdsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<AdStatus> status() => guardFailures(() async {
    final status = await _client.rpc<Map<String, dynamic>>('get_ad_status');
    return AdStatus.fromJson(status);
  });
}

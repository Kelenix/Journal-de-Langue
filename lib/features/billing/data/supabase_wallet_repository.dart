import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../domain/billing_repository.dart';
import '../domain/wallet.dart';

class SupabaseWalletRepository implements WalletRepository {
  const SupabaseWalletRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Wallet> current() => guardFailures(() async {
    final wallet = await _client.rpc<Map<String, dynamic>>('get_wallet');
    return Wallet.fromJson(wallet);
  });
}

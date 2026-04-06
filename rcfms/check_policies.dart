import 'package:supabase/supabase.dart';
import 'lib/core/constants/supabase_config.dart';

void main() async {
  final supabase = SupabaseClient(
    SupabaseConfig.url,
    SupabaseConfig.serviceRoleKey,
  );

  try {
    final response = await supabase
        .from('pg_policies')
        .select()
        .eq('tablename', 'residents');
    print(response);
  } catch (e) {
    print('Failed direct RPC call: $e');
  }
}

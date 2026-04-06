import 'package:supabase/supabase.dart';
import 'lib/core/constants/supabase_config.dart';

void main() async {
  final supabase = SupabaseClient(
    SupabaseConfig.url,
    SupabaseConfig.serviceRoleKey,
  );

  try {
    // List all routines (RPCs)
    final response =
        await supabase.rpc('get_rpc_list'); // checking if an rpc lister exists
    print(response);
  } catch (e) {
    print('Failed direct RPC call: $e');
  }
}

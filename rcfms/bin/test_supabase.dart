import 'package:http/http.dart' as http;

void main() async {
  final url =
      'https://xkurkaykkywfslakemez.supabase.co/rest/v1/profiles?select=email,title';
  final apikey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhrdXJrYXlra3l3ZnNsYWtlbWV6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg4MzQxNjEsImV4cCI6MjA4NDQxMDE2MX0.oWHoKHrerTdYqGbzEFKYDCCLNyJxVCiWz_qRu0xzARI';

  var r = await http.get(Uri.parse(url + '&email=eq.nutrl_head@gmail.com'),
      headers: {'apikey': apikey, 'Authorization': 'Bearer ' + apikey});
  print(r.body);
}

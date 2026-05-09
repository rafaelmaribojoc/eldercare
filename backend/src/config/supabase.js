const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
// Prefer anon key for regular client, but allow fallback in dev setups where only
// the service role key is configured.
const supabaseKey =
  process.env.SUPABASE_ANON_KEY ?? process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl) {
  throw new Error('SUPABASE_URL is required.');
}
if (!supabaseKey) {
  throw new Error(
    'A Supabase key is required. Set SUPABASE_ANON_KEY (recommended) or SUPABASE_SERVICE_ROLE_KEY.'
  );
}

// Regular client (uses anon key when available)
const supabase = createClient(supabaseUrl, supabaseKey);

// Admin client (uses service role key - bypasses RLS)
const supabaseAdmin = createClient(
  supabaseUrl,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
);

module.exports = { supabase, supabaseAdmin };

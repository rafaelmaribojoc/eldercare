/**
 * RCFMS User Seeding Script
 * 
 * This script creates test user accounts for development and testing.
 * Run with: node src/scripts/seed-users.js
 * 
 * Requires SUPABASE_SERVICE_ROLE_KEY in .env (not the anon key!)
 */

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

// Use service role key for admin operations
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('Error: Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env');
  console.error('Make sure you have both variables set in your .env file.');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

// Test accounts to create
const testUsers = [
  {
    email: 'superadmin@rcfms.local',
    password: 'Test@123456',
    user_metadata: {
      full_name: 'Super Administrator',
      work_id: 'RCFMS-001',
      role: 'super_admin'
    }
  },
  {
    email: 'centerhead@rcfms.local',
    password: 'Test@123456',
    user_metadata: {
      full_name: 'Maria Santos',
      work_id: 'RCFMS-002',
      role: 'center_head'
    }
  },
  {
    email: 'socialhead@rcfms.local',
    password: 'Test@123456',
    user_metadata: {
      full_name: 'Juan Dela Cruz',
      work_id: 'RCFMS-003',
      role: 'social_head'
    }
  },
  {
    email: 'socialstaff@rcfms.local',
    password: 'Test@123456',
    user_metadata: {
      full_name: 'Ana Reyes',
      work_id: 'RCFMS-004',
      role: 'social_staff'
    }
  },
  {
    email: 'homelifehead@rcfms.local',
    password: 'Test@123456',
    user_metadata: {
      full_name: 'Roberto Garcia',
      work_id: 'RCFMS-005',
      role: 'homelife_head'
    }
  },
  {
    email: 'homelifestaff@rcfms.local',
    password: 'Test@123456',
    user_metadata: {
      full_name: 'Carmen Lim',
      work_id: 'RCFMS-006',
      role: 'homelife_staff'
    }
  },
  {
    email: 'psychhead@rcfms.local',
    password: 'Test@123456',
    user_metadata: {
      full_name: 'Dr. Elena Torres',
      work_id: 'RCFMS-007',
      role: 'psych_head'
    }
  },
  {
    email: 'psychstaff@rcfms.local',
    password: 'Test@123456',
    user_metadata: {
      full_name: 'Michael Tan',
      work_id: 'RCFMS-008',
      role: 'psych_staff'
    }
  },
  {
    email: 'medicalhead@rcfms.local',
    password: 'Test@123456',
    user_metadata: {
      full_name: 'Dr. Ricardo Mendoza',
      work_id: 'RCFMS-009',
      role: 'medical_head'
    }
  },
  {
    email: 'medicalstaff@rcfms.local',
    password: 'Test@123456',
    user_metadata: {
      full_name: 'Nurse Patricia Yu',
      work_id: 'RCFMS-010',
      role: 'medical_staff'
    }
  }
];

// Unit mapping for profiles
const unitMap = {
  'super_admin': null,
  'center_head': null,
  'social_head': 'social',
  'social_staff': 'social',
  'homelife_head': 'homelife',
  'homelife_staff': 'homelife',
  'psych_head': 'psych',
  'psych_staff': 'psych',
  'medical_head': 'medical',
  'medical_staff': 'medical',
  'rehab_head': 'rehab',
  'rehab_staff': 'rehab'
};

async function seedUsers() {
  console.log('🌱 Starting RCFMS User Seeding...\n');

  let successCount = 0;
  let errorCount = 0;

  for (const user of testUsers) {
    try {
      console.log(`Creating user: ${user.email}...`);

      // Create user with admin API
      const { data, error } = await supabase.auth.admin.createUser({
        email: user.email,
        password: user.password,
        email_confirm: true, // Auto-confirm email
        user_metadata: user.user_metadata
      });

      if (error) {
        // Check if user already exists
        if (error.message.includes('already been registered') || error.message.includes('already exists')) {
          console.log(`  ⚠️  User already exists, updating profile...`);
          
          // Get existing user
          const { data: existingUsers } = await supabase.auth.admin.listUsers();
          const existingUser = existingUsers?.users?.find(u => u.email === user.email);
          
          if (existingUser) {
            // Update profile
            await updateProfile(existingUser.id, user.user_metadata);
            console.log(`  ✅ Profile updated for ${user.email}`);
            successCount++;
          }
        } else {
          throw error;
        }
      } else if (data?.user) {
        // Update the profile with unit
        await updateProfile(data.user.id, user.user_metadata);
        console.log(`  ✅ Created: ${user.email}`);
        successCount++;
      }
    } catch (err) {
      console.error(`  ❌ Error creating ${user.email}:`, err.message);
      errorCount++;
    }
  }

  console.log('\n========================================');
  console.log('🌱 Seeding Complete!');
  console.log(`   ✅ Success: ${successCount}`);
  console.log(`   ❌ Errors: ${errorCount}`);
  console.log('========================================\n');

  if (successCount > 0) {
    console.log('📋 Test Accounts:');
    console.log('   Password for all accounts: Test@123456\n');
    testUsers.forEach(u => {
      console.log(`   ${u.email.padEnd(30)} - ${u.user_metadata.role}`);
    });
    console.log('');
  }
}

async function updateProfile(userId, metadata) {
  const role = metadata.role;
  const unit = unitMap[role] || null;

  const { error } = await supabase
    .from('profiles')
    .update({
      full_name: metadata.full_name,
      work_id: metadata.work_id,
      role: role,
      unit: unit,
      updated_at: new Date().toIso8601String()
    })
    .eq('id', userId);

  if (error) {
    console.log(`     Warning: Could not update profile - ${error.message}`);
  }
}

// Run the seeding
seedUsers()
  .then(() => {
    console.log('Done!');
    process.exit(0);
  })
  .catch(err => {
    console.error('Fatal error:', err);
    process.exit(1);
  });

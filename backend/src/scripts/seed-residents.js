/**
 * RCFMS Resident Seeding Script
 * 
 * This script creates test resident records for development and testing.
 * Run with: node src/scripts/seed-residents.js
 */

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('Error: Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

// Test residents to create
const testResidents = [
  {
    first_name: 'Lola',
    last_name: 'Fernandez',
    middle_name: 'Santos',
    date_of_birth: '1945-03-15',
    gender: 'female',
    room_number: '101',
    bed_number: 'A',
    admission_date: '2024-01-15',
    emergency_contact_name: 'Maria Fernandez',
    emergency_contact_phone: '+63 912 345 6789',
    emergency_contact_relation: 'Daughter',
    medical_notes: 'Mild hypertension, controlled with medication',
    allergies: 'Penicillin',
    primary_diagnosis: 'Age-related cognitive decline',
    ward_name: 'Ward A'
  },
  {
    first_name: 'Lolo',
    last_name: 'Reyes',
    middle_name: 'Cruz',
    date_of_birth: '1940-07-22',
    gender: 'male',
    room_number: '102',
    bed_number: 'A',
    admission_date: '2024-02-20',
    emergency_contact_name: 'Pedro Reyes Jr.',
    emergency_contact_phone: '+63 917 654 3210',
    emergency_contact_relation: 'Son',
    medical_notes: 'Diabetes Type 2, insulin dependent',
    allergies: 'Sulfa drugs',
    primary_diagnosis: 'Stroke recovery',
    ward_name: 'Ward A'
  },
  {
    first_name: 'Nanay',
    last_name: 'Garcia',
    middle_name: 'Lim',
    date_of_birth: '1948-11-08',
    gender: 'female',
    room_number: '201',
    bed_number: 'B',
    admission_date: '2024-03-10',
    emergency_contact_name: 'Jose Garcia',
    emergency_contact_phone: '+63 918 765 4321',
    emergency_contact_relation: 'Son',
    medical_notes: 'Arthritis, requires wheelchair assistance',
    allergies: 'None known',
    primary_diagnosis: 'Osteoarthritis',
    ward_name: 'Ward B'
  },
  {
    first_name: 'Tatay',
    last_name: 'Santos',
    middle_name: 'Dela Cruz',
    date_of_birth: '1942-05-30',
    gender: 'male',
    room_number: '202',
    bed_number: 'A',
    admission_date: '2024-04-05',
    emergency_contact_name: 'Carmen Santos',
    emergency_contact_phone: '+63 919 876 5432',
    emergency_contact_relation: 'Wife',
    medical_notes: 'Heart condition, pacemaker installed',
    allergies: 'Aspirin',
    primary_diagnosis: 'Cardiac arrhythmia',
    ward_name: 'Ward B'
  },
  {
    first_name: 'Aling',
    last_name: 'Torres',
    middle_name: 'Mendoza',
    date_of_birth: '1950-09-12',
    gender: 'female',
    room_number: '301',
    bed_number: 'A',
    admission_date: '2024-05-18',
    emergency_contact_name: 'Elena Torres',
    emergency_contact_phone: '+63 920 987 6543',
    emergency_contact_relation: 'Daughter',
    medical_notes: 'Early stage dementia, requires supervision',
    allergies: 'Shellfish',
    primary_diagnosis: "Alzheimer's disease - early onset",
    ward_name: 'Ward C'
  },
  {
    first_name: 'Mang',
    last_name: 'Bautista',
    middle_name: 'Lopez',
    date_of_birth: '1938-12-25',
    gender: 'male',
    room_number: '302',
    bed_number: 'B',
    admission_date: '2024-06-01',
    emergency_contact_name: 'Rosa Bautista',
    emergency_contact_phone: '+63 921 098 7654',
    emergency_contact_relation: 'Daughter',
    medical_notes: 'Parkinson\'s disease, tremors managed with medication',
    allergies: 'None known',
    primary_diagnosis: 'Parkinson\'s disease',
    ward_name: 'Ward C'
  },
  {
    first_name: 'Inay',
    last_name: 'Villanueva',
    middle_name: 'Ramos',
    date_of_birth: '1946-06-18',
    gender: 'female',
    room_number: '401',
    bed_number: 'A',
    admission_date: '2024-07-10',
    emergency_contact_name: 'Antonio Villanueva',
    emergency_contact_phone: '+63 922 109 8765',
    emergency_contact_relation: 'Son',
    medical_notes: 'Post hip surgery, rehabilitation ongoing',
    allergies: 'Iodine',
    primary_diagnosis: 'Hip fracture recovery',
    ward_name: 'Ward D'
  },
  {
    first_name: 'Itay',
    last_name: 'Pascual',
    middle_name: 'Ocampo',
    date_of_birth: '1943-02-14',
    gender: 'male',
    room_number: '402',
    bed_number: 'B',
    admission_date: '2024-08-05',
    emergency_contact_name: 'Luisa Pascual',
    emergency_contact_phone: '+63 923 210 9876',
    emergency_contact_relation: 'Wife',
    medical_notes: 'COPD, requires oxygen therapy',
    allergies: 'Latex',
    primary_diagnosis: 'Chronic obstructive pulmonary disease',
    ward_name: 'Ward D'
  }
];

async function getWardId(wardName) {
  const { data, error } = await supabase
    .from('wards')
    .select('id')
    .eq('name', wardName)
    .single();

  if (error) {
    console.error(`Error finding ward ${wardName}:`, error.message);
    return null;
  }
  return data?.id;
}

async function seedResidents() {
  console.log('🏥 Starting RCFMS Resident Seeding...\n');

  let successCount = 0;
  let errorCount = 0;

  for (const resident of testResidents) {
    try {
      console.log(`Creating resident: ${resident.first_name} ${resident.last_name}...`);

      // Get ward ID
      const wardId = await getWardId(resident.ward_name);
      if (!wardId) {
        console.log(`  ⚠️  Ward not found: ${resident.ward_name}, skipping...`);
        errorCount++;
        continue;
      }

      // Check if resident already exists
      const { data: existing } = await supabase
        .from('residents')
        .select('id')
        .eq('first_name', resident.first_name)
        .eq('last_name', resident.last_name)
        .eq('date_of_birth', resident.date_of_birth)
        .single();

      if (existing) {
        console.log(`  ⚠️  Resident already exists, skipping...`);
        successCount++;
        continue;
      }

      // Create resident record
      const { ward_name, ...residentData } = resident;
      const { error } = await supabase
        .from('residents')
        .insert({
          ...residentData,
          ward_id: wardId,
          is_active: true
        });

      if (error) throw error;

      console.log(`  ✅ Created: ${resident.first_name} ${resident.last_name}`);
      successCount++;

    } catch (err) {
      console.error(`  ❌ Error:`, err.message);
      errorCount++;
    }
  }

  // Update ward occupancy counts
  console.log('\nUpdating ward occupancy counts...');
  const { data: wards } = await supabase.from('wards').select('id');
  
  for (const ward of wards || []) {
    const { count } = await supabase
      .from('residents')
      .select('*', { count: 'exact', head: true })
      .eq('ward_id', ward.id)
      .eq('is_active', true);

    await supabase
      .from('wards')
      .update({ current_occupancy: count || 0 })
      .eq('id', ward.id);
  }

  console.log('\n========================================');
  console.log('🏥 Resident Seeding Complete!');
  console.log(`   ✅ Success: ${successCount}`);
  console.log(`   ❌ Errors: ${errorCount}`);
  console.log('========================================\n');
}

// Run the seeding
seedResidents()
  .then(() => {
    console.log('Done!');
    process.exit(0);
  })
  .catch(err => {
    console.error('Fatal error:', err);
    process.exit(1);
  });

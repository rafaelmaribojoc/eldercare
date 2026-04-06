# RCFMS - Resident Care & Facility Management System

A comprehensive digital profile platform for eldercare facilities, transitioning from paper-based case folders to a centralized, role-based digital system.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)

## 🌟 Features

### Core Functionality
- **Resident Digital Timeline**: Real-time feed of approved forms and records powered by Supabase Realtime
- **Standardized Fixed Forms**: Hardcoded templates for each unit (Social, Medical, Psych, Rehab, Homelife)
- **Approval Engine**: State machine workflow (Draft → Submitted → Pending Review → Approved/Returned)
- **Ward-Based NFC System**: Scan ward tags to access residents in that location
- **E-Signature Management**: Digital signatures stored and applied to all forms

### Role-Based Access Control (RBAC)
| Layer | Roles |
|-------|-------|
| Administration | Super Admin, Center Head |
| Unit Heads | Social, Medical, Psych, Rehab, Homelife Heads |
| Staff | Unit-specific staff members |

### Security Features
- No public sign-up (admin-provisioned accounts only)
- Locked fields (Full Name, Work ID) for accountability
- Row Level Security (RLS) on all tables
- Audit logging for sensitive operations

## 📁 Project Structure

```
ElderCare/
├── rcfms/                    # Flutter Application
│   ├── lib/
│   │   ├── core/
│   │   │   ├── constants/    # App constants, Supabase config
│   │   │   ├── theme/        # Colors, typography, theme
│   │   │   ├── services/     # Router, utilities
│   │   │   └── widgets/      # Shared widgets
│   │   ├── data/
│   │   │   ├── models/       # Data models
│   │   │   └── repositories/ # Data access layer
│   │   └── features/
│   │       ├── auth/         # Authentication
│   │       ├── dashboard/    # Home dashboard
│   │       ├── residents/    # Resident management
│   │       ├── forms/        # Form submission & templates
│   │       ├── timeline/     # Digital timeline
│   │       ├── approvals/    # Form approval workflow
│   │       ├── nfc/          # NFC scanning
│   │       ├── signature/    # E-signature setup
│   │       ├── admin/        # Admin panel
│   │       └── settings/     # User settings
│   └── assets/
├── backend/                  # Node.js Backend
│   └── src/
│       ├── config/           # Supabase client config
│       ├── middleware/       # Auth middleware
│       ├── routes/           # API routes
│       └── services/         # Email, utilities
└── supabase/
    └── migrations/           # Database schema
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Node.js (>=18.x)
- Supabase Account

### 1. Supabase Setup

1. Create a new Supabase project at [supabase.com](https://supabase.com)
2. Run the migration in `supabase/migrations/001_initial_schema.sql`
3. Create storage buckets:
   - `signatures` (private)
   - `resident_photos` (private)
   - `documents` (private)
4. Copy your project URL and keys

### 2. Flutter App Setup

```bash
cd rcfms

# Install dependencies
flutter pub get

# Configure Supabase (edit this file)
# lib/core/constants/supabase_config.dart

# Run the app
flutter run
```

### 3. Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Create .env file from template
cp .env.example .env
# Edit .env with your credentials

# Start development server
npm run dev
```

### 4. Create First Super Admin

Since there's no public sign-up, create the first super admin via Supabase Dashboard:

1. Go to Authentication → Users → Invite user
2. After user is created, update their profile in the `profiles` table:
   ```sql
   UPDATE profiles 
   SET role = 'super_admin', 
       full_name = 'Admin Name', 
       work_id = 'ADMIN001'
   WHERE email = 'admin@example.com';
   ```

## 📱 Form Templates

Each unit has specific form templates:

| Unit | Forms |
|------|-------|
| **Social** | Intake Form, Family Conference Log |
| **Medical** | Daily Vitals, Incident Report, Medical Abstract |
| **Psych** | MOCA-P Scoring Sheet, Behavior Log |
| **Rehab** | Therapy Session Notes |
| **Homelife** | Daily Activity Log |

## 🔐 Environment Variables

### Flutter (`supabase_config.dart`)
```dart
static const String url = 'YOUR_SUPABASE_URL';
static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
static const String backendUrl = 'http://localhost:3000/api';
```

### Backend (`.env`)
```env
PORT=3000
SUPABASE_URL=your-project-url
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
```

## 📄 API Endpoints

### Admin Routes (Super Admin only)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/admin/users` | Provision new user |
| GET | `/api/admin/users` | Get all users |
| PATCH | `/api/admin/users/:id` | Update user |
| DELETE | `/api/admin/users/:id` | Deactivate user |
| GET | `/api/admin/audit-logs` | Get audit logs |

### PDF Routes
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/pdf/case-abstract/:residentId` | Generate case abstract PDF |

## 🎨 Design System

### Colors
- **Primary**: Warm Teal (#2A9D8F) - Trust, Care, Calm
- **Secondary**: Soft Coral (#E07A5F) - Warmth, Comfort
- **Accent**: Golden Sand (#F4A261) - Positivity, Energy

### Unit Colors
- Social: Purple (#7B68EE)
- Medical: Green (#4CAF50)
- Psychology: Violet (#9C27B0)
- Rehabilitation: Cyan (#00BCD4)
- Homelife: Orange (#FF9800)

## 📝 License

This project is developed as a capstone project for eldercare facility management.

## 🤝 Contributing

This is a capstone project. For questions or suggestions, please contact the development team.

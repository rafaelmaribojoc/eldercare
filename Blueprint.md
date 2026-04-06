# Resident Care & Facility Management System (RCFMS) - Project Blueprint

## 1. Executive Summary
* **Project Name:** RCFMS (Resident Care & Facility Management System)
* **Vision:** To transition the facility from "bulky paper case folders" to a "Single Source of Truth" digital profile for every resident.
* **Objective:** Create a centralized, role-based platform where resident history and assessments are captured via standardized digital forms, accessed via location-based NFC scanning, and secured by strict chain-of-custody identity management.

## 2. User Roles & Permissions (RBAC)

### A. Administration Layer
| Role | Responsibility | Key Privileges |
| :--- | :--- | :--- |
| **Super Admin** | System Owner & Security | **Exclusive User Provisioning** (Supabase Admin API), Master Data Config (Wards, NFC Tags), Audit Logs. |
| **Center Head (Admin)** | Operational Oversight | View **Global Digital Timeline**, Approve/Return high-level submissions, View Facility Analytics. |

### B. Service Unit Heads (Middle Management)
*Departments: Social Services, Medical, Psychological, Rehabilitation, Homelife.*
* **Reviewer:** Signs (Approves) or Returns forms submitted by their staff.
* **Gatekeeper (Social Head Only):** Exclusive rights to Add New Residents and assign them to specific Wards in the database.
* **Specialist (Psych Head Only):** Administers the MOCA-P assessment.

### C. Service Staff (Frontline)
* **Operator:** Scans **Ward NFC Tags** to locate residents.
* **Reporter:** Selects a **Fixed Template** (e.g., "Daily Vitals") and inputs data.
* **Signatory:** Applies digital signature to forms before submission.
* **Constraint:** Can only edit forms *before* submission or if *returned* by Head.

## 3. Security & Onboarding Workflow

### 3.1 Strict "No Public Sign-Up" Policy
To ensure accountability and prevent "ghost" employees:
1.  **Verification:** Employee presents physical Work ID to Super Admin.
2.  **Provisioning:** Super Admin inputs `Full Name`, `Work ID`, and `Email` into the Admin Panel.
3.  **Backend Action:** Node.js API calls Supabase Admin Auth to create the user without sending a confirmation email immediately.
4.  **Delivery:** Node.js generates a temporary password and sends credentials via SMTP (e.g., Nodemailer).

### 3.2 Hybrid Profile Management
* **LOCKED Fields (Read-Only for User):**
    * *Full Name* (Legal Accountability).
    * *Work ID* (Identity Verification).
    * *Note:* These are protected via **Supabase Row Level Security (RLS)** rules.
* **EDITABLE Fields (User Controlled):**
    * *Username*, *Password*, and *Digital Signature*.

### 3.3 E-Signature Management
* **Setup:** Users draw their signature on a digital canvas in Settings upon first login.
* **Storage:** The signature is saved as a PNG in **Supabase Storage** (Private Bucket).
* **Usage:** When a user clicks "Sign & Submit," the system references their stored signature URL to "stamp" the document.

## 4. Key Modules & Features

### 4.1 Resident Digital Timeline (The Core)
* **Real-Time Feed:** Powered by **Supabase Realtime**. As soon as a Head approves a form, it instantly pushes to the resident's timeline stream.
* **Filters:** Toggle views (e.g., "Show Medical Logs," "Show Social History").
* **Search:** PostgreSQL Full Text Search for retrieving past incidents.

### 4.2 Standardized Fixed Forms (No Form Builder)
The system uses **Hardcoded Templates** tailored to each unit to ensure data consistency.
* **Social Unit:** Intake Form, Family Conference Log.
* **Medical Unit:** Daily Vitals Sheet, Incident Report, Medical Abstract.
* **Psych Unit:** MOCA-P Scoring Sheet, Behavior Log.
* **Rehab Unit:** Therapy Session Notes.
* **Homelife Unit:** Daily Activity Log.

### 4.3 The Approval Engine (State Machine)
1.  **Draft:** Staff enters data.
2.  **Signed & Submitted:** Staff applies E-Signature. Form is **Locked** (RLS Rule: `update` disabled for Staff).
3.  **Pending Review:** Unit Head receives notification.
    * *Action A (Approve):* Head signs. Form becomes **Final Record**.
    * *Action B (Return):* Head adds comment. Status updates to `Returned`. RLS Rule enables `update` for Staff again.

### 4.4 Ward-Based NFC System (Location Scanning)
Instead of tagging people, the facility tags the **Rooms/Wards**.
* **Setup (Admin/Social Head):** A physical NFC tag is mounted at the entrance of each Ward.
* **The Workflow:**
    1.  **Scan:** Staff enters the room and scans the **Ward Tag**.
    2.  **Identify:** App queries Supabase: `SELECT * FROM residents WHERE ward_id = 'scanned_id'`.
    3.  **Select:** App displays a list of residents (photos + names).
    4.  **Action:** Staff clicks the specific resident to open their **Digital Timeline**.

### 4.5 Utility Export (The Emergency Hatch)
* **Purpose:** For hospital transfers or audits ONLY.
* **Function:** Node.js API fetches data and uses a library (like `pdfkit` or `puppeteer`) to generate a "Case Abstract" PDF.

## 5. Technical Architecture

### 5.1 Tech Stack
* **Frontend:** **Flutter** (Mobile & Web).
    * *Packages:* `nfc_manager`, `hand_signature`, `supabase_flutter`.
* **Backend:** **Node.js (Express.js)**.
    * *Role:* Acts as the secure "Middleman" for Admin tasks (creating users via Admin API) and generating PDFs.
* **Database & Auth:** **Supabase**.
    * *Auth:* Manages JWT Tokens and User Sessions.
    * *Database:* PostgreSQL (hosted on Supabase).
    * *Realtime:* Broadcasting updates to the Timeline.
    * *Storage:* Buckets for `resident_photos` and `signatures`.
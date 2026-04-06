# Signature Tags for All Forms

Identified signature and signatory tags extracted from `.docx` templates.

## Home Life Service\incident_report.docx
 - `{{ prepared_by }}` / `{{ prepared_by_signature_url }}`
 - `{{ attested_by }}` / `{{ attested_by_signature_url }}`
 - `{{ received_social }}` / `{{ received_social_signature_url }}`
 - `{{ received_psych }}` / `{{ received_psych_signature_url }}`
 - `{{ received_medical }}` / `{{ received_medical_signature_url }}`
 - `{{ noted_by }}` / `{{ noted_by_signature_url }}`

## Home Life Service\inventory_upon_admission.docx
 - `{{ client_signature_url }}` (Client Signature)
 - `{{ inventory_date }}`
 - `{{ referring_party }}` / `{{ referring_party_signature_url }}` (Turned Over By)
 - `{{ received_by }}` / `{{ received_by_signature_url }}` (Received By)
 - `{{ inspected_by }}` / `{{ inspected_by_signature_url }}`
 - `{{ attested_by }}` / `{{ attested_by_signature_url }}`
 - `{{ noted_by }}` / `{{ noted_by_signature_url }}`

## Home Life Service\inventory_discharge.docx
 - `{{ client_name }}`
 - `{{ inventory_date }}`
 - `{{ receiving_party }}` / `{{ receiving_party_signature_url }}`
 - `{{ inspected_by }}` / `{{ inspected_by_signature_url }}`
 - `{{ attested_by }}` / `{{ attested_by_signature_url }}`
 - `{{ noted_by }}` / `{{ noted_by_signature_url }}`

## Home Life Service\inventory_monthly.docx
 - `{{ client_name }}`
 - `{{ inventory_date }}`
 - `{{ month }}`
 - `{{ year }}`
 - `{{ prepared_by }}` / `{{ prepared_by_signature_url }}`
 - `{{ submitted_by }}` / `{{ submitted_by_signature_url }}`
 - `{{ noted_by }}` / `{{ noted_by_signature_url }}`

## Home Life Service\out_on_pass.docx
 - `{{ client_name }}`
 - `{{ pass_date }}`
 - `{{ time_out }}`
 - `{{ time_in }}`
 - `{{ supervising_hp }}` / `{{ supervising_hp_signature_url }}`
 - `{{ escorted_by }}` / `{{ escorted_by_signature_url }}`
 - `{{ received_by }}` / `{{ received_by_signature_url }}`
 - `{{ social_worker }}` / `{{ social_worker_signature_url }}`
 - `{{ noted_by }}` / `{{ noted_by_signature_url }}`
 - `{{ nature_personal_chk }}`
 - `{{ nature_medical_chk }}`
 - `{{ nature_official_chk }}`

## Home Life Service\progress_notes.docx
 - `{{ client_name }}`
 - `{{ center_doctor }}` / `{{ center_doctor_signature_url }}`
 - `{{ social_worker }}` / `{{ social_worker_signature_url }}`
 - `{{ approved_by }}` / `{{ approved_by_signature_url }}`

## Social Service\admission_case_conference.docx
 - `{{ noted_by }}` / `{{ noted_by_signature_url }}`
 - `{{ prepared_by }}` / `{{ prepared_by_signature_url }}`

## Social Service\admission_slip.docx
 - `{{ center_head_signature_url }}`
 - `{{ medical_staff_name_signature_url }}`
 - `{{ prepared_by_signature_url }}`

## Social Service\general_intake_sheet.docx
 - `{{ prepared_by }}` / `{{ prepared_by_signature_url }}`
 - `{{ applicant_signature_url }}` (Applicant)

## Social Service\requirements_checklist.docx
 - `{{ endorsed_by_signature_url }}` (Endorsed By)

## Social Service\clients_contract.docx
 - `{{ custodian_signature_url }}` (Custodian)
 - `{{ witness1_signature_url }}` (Witness 1)
 - `{{ witness2_signature_url }}` (Witness 2)

## Social Service\kasunduan.docx
 - `{{ client_signature_url }}` (Client)

## Social Service\intervention_plan.docx
 - `{{ client_signature_url }}` (Client)

## Social Service\termination_report.docx
 - `{{ division_chief_name }}` / `{{ division_chief_signature_url }}` (Division Chief)
 - `{{ regional_director_name }}` / `{{ regional_director_signature_url }}` (Regional Director)

## External Signatories Audit
| Document | Signatory | Tags |
|---|---|---|
| **Discharge Slip** | C/MSWDO | `{{ cmswdo_name }}` / `{{ cmswdo_signature_url }}` |
| **Case Transfer Summary** | C/MSWDO | `{{ received_by }}` / `{{ received_by_signature_url }}` |
| **Intervention Plan** | Client Signature | `{{ client_signature_url }}` |
| **Termination Report** | Division Chief | `{{ division_chief_name }}` / `{{ division_chief_signature_url }}` |
| **Termination Report** | Regional Director | `{{ regional_director_name }}` / `{{ regional_director_signature_url }}` |

## Social Service\discharge_slip.docx
 - `{{ receiving_party_signature_url }}` (Receiving Party)
 - `{{ cmswdo_name }}` / `{{ cmswdo_signature_url }}` (C/MSWDO)

## Social Service\case_transfer_summary.docx
 - `{{ received_by }}` / `{{ received_by_signature_url }}` (C/MSWDO)

## Social Service\case_transfer_summary.docx
 - `{{ received_by }}` / `{{ received_by_signature_url }}` (C/MSWDO)

## Psychological & Medical Services (All Reports)
 - `{{ prepared_by_signature_url }}` (Prepared By)
 - `{{ attested_by_signature_url }}` (Attested By)
 - `{{ referring_party_signature_url }}` (Referring Party - for Inter-Service Referral)

> [!TIP]
> Use the above tags in your .docx templates. The system will automatically resolve signature URLs based on the user who signed the form.

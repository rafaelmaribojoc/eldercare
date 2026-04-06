# After Care Plan – Word Template Merge Tags

Use these form data keys in your Word template for mail merge or placeholder replacement.

## Names and designations

| Tag (use in Word) | Description |
|-------------------|-------------|
| `prepared_by` | Name of preparer (Social Worker) |
| `user_name` | Same as prepared_by when prepared_by is not set |
| `prepared_by_title` or `user_title` | Designation/title of preparer |
| `social_head_name` | Social Service Head name (step 1) |
| `confirmed_social` | Social Head confirmation name (workflow) |
| `confirmed_homelife` | Homelife Head name |
| `confirmed_medical` | Medical Head name |
| `confirmed_psych` | Psych Head name |
| `cmswdo_name` | C/MSWDO (external signatory) name |
| `center_head_name` or `noted_by` | Center Head name (final approval) |

## Signature URL tags (for every head – use in Word for signature images)

These are the exact keys used for signature image URLs in export/form data. Use them in your Word template to embed each signatory’s signature image.

| Signatory | Name tag | Signature URL tag |
|-----------|----------|-------------------|
| Prepared by (Social Worker) | `prepared_by` | `prepared_by_signature_url` |
| Social Head | `confirmed_social` | `confirmed_social_signature_url` |
| Homelife Head | `confirmed_homelife` | `confirmed_homelife_signature_url` |
| Medical Head | `confirmed_medical` | `confirmed_medical_signature_url` |
| Psych Head | `confirmed_psych` | `confirmed_psych_signature_url` |
| C/MSWDO | `cmswdo_name` | `cmswdo_signature_url` |
| Center Head (Noted by) | `noted_by` or `center_head_name` | `noted_by_signature_url` |

## Example Word merge fields

- Prepared by: `«prepared_by»` — Designation: `«prepared_by_title»`
- Social Head: `«confirmed_social»` — Signature: `«confirmed_social_signature_url»`
- Homelife Head: `«confirmed_homelife»` — Signature: `«confirmed_homelife_signature_url»`
- Medical Head: `«confirmed_medical»` — Signature: `«confirmed_medical_signature_url»`
- Psych Head: `«confirmed_psych»` — Signature: `«confirmed_psych_signature_url»`
- C/MSWDO: `«cmswdo_name»` — Signature: `«cmswdo_signature_url»`
- Noted by (Center Head): `«noted_by»` — Signature: `«noted_by_signature_url»`

For signature images in Word, use the URL tags in an INCLUDEPICTURE or similar field if your merge supports images.

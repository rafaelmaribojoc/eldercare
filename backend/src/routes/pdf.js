const express = require('express');
const PDFDocument = require('pdfkit');
const { supabaseAdmin } = require('../config/supabase');
const { verifyToken, requireUnitHead } = require('../middleware/auth');

const router = express.Router();

/**
 * GET /api/pdf/case-abstract/:residentId
 * Generate case abstract PDF for a resident
 */
router.get('/case-abstract/:residentId', verifyToken, async (req, res) => {
  try {
    const { residentId } = req.params;

    // Fetch resident data
    const { data: resident, error: residentError } = await supabaseAdmin
      .from('residents')
      .select('*, ward:wards(name)')
      .eq('id', residentId)
      .single();

    if (residentError || !resident) {
      return res.status(404).json({ error: 'Resident not found' });
    }

    // Fetch approved forms
    const { data: forms, error: formsError } = await supabaseAdmin
      .from('form_submissions')
      .select(`
        *,
        submitter:profiles!form_submissions_submitted_by_fkey(full_name),
        reviewer:profiles!form_submissions_reviewed_by_fkey(full_name)
      `)
      .eq('resident_id', residentId)
      .eq('status', 'approved')
      .order('created_at', { ascending: false })
      .limit(20);

    if (formsError) {
      console.error('Forms fetch error:', formsError);
    }

    // Create PDF
    const doc = new PDFDocument({
      size: 'A4',
      margins: { top: 50, bottom: 50, left: 50, right: 50 },
    });

    // Set response headers
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader(
      'Content-Disposition',
      `attachment; filename="case-abstract-${resident.last_name}-${resident.first_name}.pdf"`
    );

    // Pipe PDF to response
    doc.pipe(res);

    // Header
    doc
      .fillColor('#2A9D8F')
      .fontSize(24)
      .font('Helvetica-Bold')
      .text('CASE ABSTRACT', { align: 'center' });
    
    doc
      .fontSize(10)
      .font('Helvetica')
      .fillColor('#666')
      .text('Resident Care & Facility Management System', { align: 'center' });
    
    doc
      .text(`Generated: ${new Date().toLocaleString()}`, { align: 'center' })
      .moveDown(2);

    // Resident Information Section
    doc
      .fillColor('#264653')
      .fontSize(14)
      .font('Helvetica-Bold')
      .text('RESIDENT INFORMATION')
      .moveDown(0.5);

    doc.strokeColor('#2A9D8F').lineWidth(2).moveTo(50, doc.y).lineTo(545, doc.y).stroke();
    doc.moveDown(0.5);

    const fullName = [resident.first_name, resident.middle_name, resident.last_name]
      .filter(Boolean)
      .join(' ');

    const age = calculateAge(resident.date_of_birth);

    const infoRows = [
      ['Full Name', fullName],
      ['Date of Birth', formatDate(resident.date_of_birth)],
      ['Age', `${age} years old`],
      ['Gender', resident.gender ? resident.gender.charAt(0).toUpperCase() + resident.gender.slice(1) : 'N/A'],
      ['Ward', resident.ward?.name || 'N/A'],
      ['Room/Bed', [resident.room_number, resident.bed_number].filter(Boolean).join(' / ') || 'N/A'],
      ['Admission Date', formatDate(resident.admission_date)],
    ];

    doc.fontSize(10).font('Helvetica');
    infoRows.forEach(([label, value]) => {
      doc
        .fillColor('#666')
        .text(`${label}:`, 50, doc.y, { continued: true, width: 150 })
        .fillColor('#264653')
        .text(` ${value}`);
    });

    doc.moveDown(1.5);

    // Emergency Contact
    if (resident.emergency_contact_name) {
      doc
        .fillColor('#264653')
        .fontSize(14)
        .font('Helvetica-Bold')
        .text('EMERGENCY CONTACT')
        .moveDown(0.5);

      doc.strokeColor('#E07A5F').lineWidth(2).moveTo(50, doc.y).lineTo(545, doc.y).stroke();
      doc.moveDown(0.5);

      doc.fontSize(10).font('Helvetica');
      doc
        .fillColor('#666')
        .text('Name:', { continued: true, width: 150 })
        .fillColor('#264653')
        .text(` ${resident.emergency_contact_name}`);
      
      if (resident.emergency_contact_phone) {
        doc
          .fillColor('#666')
          .text('Phone:', { continued: true, width: 150 })
          .fillColor('#264653')
          .text(` ${resident.emergency_contact_phone}`);
      }
      
      if (resident.emergency_contact_relation) {
        doc
          .fillColor('#666')
          .text('Relationship:', { continued: true, width: 150 })
          .fillColor('#264653')
          .text(` ${resident.emergency_contact_relation}`);
      }

      doc.moveDown(1.5);
    }

    // Medical Information
    doc
      .fillColor('#264653')
      .fontSize(14)
      .font('Helvetica-Bold')
      .text('MEDICAL INFORMATION')
      .moveDown(0.5);

    doc.strokeColor('#4CAF50').lineWidth(2).moveTo(50, doc.y).lineTo(545, doc.y).stroke();
    doc.moveDown(0.5);

    doc.fontSize(10).font('Helvetica');
    
    if (resident.primary_diagnosis) {
      doc
        .fillColor('#666')
        .text('Primary Diagnosis:', { continued: true, width: 150 })
        .fillColor('#264653')
        .text(` ${resident.primary_diagnosis}`);
    }
    
    if (resident.allergies) {
      doc
        .fillColor('#666')
        .text('Allergies:', { continued: true, width: 150 })
        .fillColor('#E53935')
        .text(` ${resident.allergies}`);
    }
    
    if (resident.medical_notes) {
      doc.moveDown(0.5);
      doc.fillColor('#666').text('Notes:');
      doc.fillColor('#264653').text(resident.medical_notes, { indent: 20 });
    }

    doc.moveDown(1.5);

    // Recent Forms/Records
    if (forms && forms.length > 0) {
      doc
        .fillColor('#264653')
        .fontSize(14)
        .font('Helvetica-Bold')
        .text('RECENT RECORDS')
        .moveDown(0.5);

      doc.strokeColor('#F4A261').lineWidth(2).moveTo(50, doc.y).lineTo(545, doc.y).stroke();
      doc.moveDown(0.5);

      doc.fontSize(9);
      forms.slice(0, 10).forEach((form, index) => {
        const formName = formatFormType(form.template_type);
        const date = formatDate(form.submitted_at || form.created_at);
        const submitter = form.submitter?.full_name || 'Unknown';

        doc
          .fillColor('#264653')
          .font('Helvetica-Bold')
          .text(`${index + 1}. ${formName}`, { continued: true })
          .font('Helvetica')
          .fillColor('#666')
          .text(` - ${date} by ${submitter}`);
      });
    }

    // Footer
    doc.moveDown(2);
    doc
      .fontSize(8)
      .fillColor('#999')
      .text(
        'This document is generated for authorized purposes only. ' +
        'Handle with care and dispose of properly.',
        { align: 'center' }
      );

    // Finalize PDF
    doc.end();

    // Log the export
    await supabaseAdmin.from('audit_logs').insert({
      user_id: req.profile.id,
      action: 'EXPORT_CASE_ABSTRACT',
      table_name: 'residents',
      record_id: residentId,
    });

  } catch (error) {
    console.error('PDF generation error:', error);
    res.status(500).json({ error: 'Failed to generate PDF' });
  }
});

// Helper functions
function calculateAge(dateOfBirth) {
  const dob = new Date(dateOfBirth);
  const now = new Date();
  let age = now.getFullYear() - dob.getFullYear();
  const monthDiff = now.getMonth() - dob.getMonth();
  if (monthDiff < 0 || (monthDiff === 0 && now.getDate() < dob.getDate())) {
    age--;
  }
  return age;
}

function formatDate(dateString) {
  if (!dateString) return 'N/A';
  const date = new Date(dateString);
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
}

function formatFormType(type) {
  if (!type) return 'Unknown';
  return type
    .split('_')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

module.exports = router;

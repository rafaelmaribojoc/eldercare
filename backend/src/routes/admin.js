const express = require('express');
const { body, validationResult } = require('express-validator');
const crypto = require('crypto');
const { supabaseAdmin } = require('../config/supabase');
const { verifyToken, requireSuperAdmin } = require('../middleware/auth');
const { sendWelcomeEmail } = require('../services/email');

const router = express.Router();

/**
 * POST /api/admin/users
 * Provision a new user (Super Admin only)
 */
router.post(
  '/users',
  verifyToken,
  requireSuperAdmin,
  [
    body('email').isEmail().withMessage('Valid email required'),
    body('full_name').notEmpty().withMessage('Full name required'),
    body('work_id').notEmpty().withMessage('Work ID required'),
    body('role').isIn([
      'super_admin',
      'center_head',
      'social_head',
      'medical_head',
      'psych_head',
      'rehab_head',
      'homelife_head',
      'social_staff',
      'medical_staff',
      'psych_staff',
      'rehab_staff',
      'homelife_staff',
    ]).withMessage('Invalid role'),
  ],
  async (req, res) => {
    try {
      // Validate request
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { email, full_name, work_id, role, unit } = req.body;

      // Check if user already exists
      const { data: existingUser } = await supabaseAdmin
        .from('profiles')
        .select('id')
        .or(`email.eq.${email},work_id.eq.${work_id}`)
        .single();

      if (existingUser) {
        return res.status(409).json({ 
          error: 'User with this email or work ID already exists' 
        });
      }

      // Generate temporary password
      const temporaryPassword = crypto.randomBytes(8).toString('hex');

      // Create user in Supabase Auth
      const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
        email,
        password: temporaryPassword,
        email_confirm: true, // Auto-confirm email
        user_metadata: {
          full_name,
          work_id,
          role,
        },
      });

      if (authError) {
        console.error('Auth creation error:', authError);
        return res.status(500).json({ error: 'Failed to create user account' });
      }

      // Update the profile with additional info (profile is auto-created by trigger)
      const { error: profileError } = await supabaseAdmin
        .from('profiles')
        .update({
          full_name,
          work_id,
          role,
          unit: unit || null,
        })
        .eq('id', authData.user.id);

      if (profileError) {
        console.error('Profile update error:', profileError);
        // Don't fail - profile trigger might handle this
      }

      // Send welcome email with credentials
      try {
        await sendWelcomeEmail({
          email,
          fullName: full_name,
          workId: work_id,
          temporaryPassword,
        });
      } catch (emailError) {
        console.error('Email send error:', emailError);
        // Don't fail the request if email fails
      }

      // Log the action
      await supabaseAdmin.from('audit_logs').insert({
        user_id: req.profile.id,
        action: 'CREATE_USER',
        table_name: 'profiles',
        record_id: authData.user.id,
        new_data: { email, full_name, work_id, role, unit },
      });

      res.status(201).json({
        message: 'User created successfully',
        user: {
          id: authData.user.id,
          email,
          full_name,
          work_id,
          role,
          unit,
        },
      });
    } catch (error) {
      console.error('Create user error:', error);
      res.status(500).json({ error: 'Failed to create user' });
    }
  }
);

/**
 * GET /api/admin/users
 * Get all users (Super Admin only)
 */
router.get('/users', verifyToken, requireSuperAdmin, async (req, res) => {
  try {
    const { data: users, error } = await supabaseAdmin
      .from('profiles')
      .select('*')
      .order('full_name', { ascending: true });

    if (error) throw error;

    res.json({ users });
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

/**
 * PATCH /api/admin/users/:id
 * Update user (Super Admin only)
 */
router.patch('/users/:id', verifyToken, requireSuperAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { role, unit, is_active } = req.body;

    const updates = {};
    if (role !== undefined) updates.role = role;
    if (unit !== undefined) updates.unit = unit;
    if (is_active !== undefined) updates.is_active = is_active;
    updates.updated_at = new Date().toISOString();

    const { data, error } = await supabaseAdmin
      .from('profiles')
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    // Log the action
    await supabaseAdmin.from('audit_logs').insert({
      user_id: req.profile.id,
      action: 'UPDATE_USER',
      table_name: 'profiles',
      record_id: id,
      new_data: updates,
    });

    res.json({ user: data });
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({ error: 'Failed to update user' });
  }
});

/**
 * DELETE /api/admin/users/:id
 * Deactivate user (Super Admin only) - Soft delete
 */
router.delete('/users/:id', verifyToken, requireSuperAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    // Don't allow deleting yourself
    if (id === req.profile.id) {
      return res.status(400).json({ error: 'Cannot deactivate your own account' });
    }

    const { error } = await supabaseAdmin
      .from('profiles')
      .update({ is_active: false, updated_at: new Date().toISOString() })
      .eq('id', id);

    if (error) throw error;

    // Log the action
    await supabaseAdmin.from('audit_logs').insert({
      user_id: req.profile.id,
      action: 'DEACTIVATE_USER',
      table_name: 'profiles',
      record_id: id,
    });

    res.json({ message: 'User deactivated successfully' });
  } catch (error) {
    console.error('Deactivate user error:', error);
    res.status(500).json({ error: 'Failed to deactivate user' });
  }
});

/**
 * GET /api/admin/audit-logs
 * Get audit logs (Super Admin only)
 */
router.get('/audit-logs', verifyToken, requireSuperAdmin, async (req, res) => {
  try {
    const { page = 0, limit = 50 } = req.query;
    const offset = parseInt(page) * parseInt(limit);

    const { data: logs, error } = await supabaseAdmin
      .from('audit_logs')
      .select('*, user:profiles(full_name)')
      .order('created_at', { ascending: false })
      .range(offset, offset + parseInt(limit) - 1);

    if (error) throw error;

    res.json({ logs });
  } catch (error) {
    console.error('Get audit logs error:', error);
    res.status(500).json({ error: 'Failed to fetch audit logs' });
  }
});

module.exports = router;

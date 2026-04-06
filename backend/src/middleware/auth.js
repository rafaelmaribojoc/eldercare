const { supabase } = require('../config/supabase');

/**
 * Middleware to verify JWT token from Supabase
 */
const verifyToken = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'No token provided' });
    }

    const token = authHeader.substring(7);

    // Verify token with Supabase
    const { data: { user }, error } = await supabase.auth.getUser(token);

    if (error || !user) {
      return res.status(401).json({ error: 'Invalid token' });
    }

    // Get user profile
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .single();

    if (profileError || !profile) {
      return res.status(401).json({ error: 'User profile not found' });
    }

    // Attach user and profile to request
    req.user = user;
    req.profile = profile;

    next();
  } catch (error) {
    console.error('Auth middleware error:', error);
    res.status(500).json({ error: 'Authentication failed' });
  }
};

/**
 * Middleware to check if user is super admin
 */
const requireSuperAdmin = (req, res, next) => {
  if (req.profile?.role !== 'super_admin') {
    return res.status(403).json({ error: 'Super admin access required' });
  }
  next();
};

/**
 * Middleware to check if user is any admin (super admin or center head)
 */
const requireAdmin = (req, res, next) => {
  const adminRoles = ['super_admin', 'center_head'];
  if (!adminRoles.includes(req.profile?.role)) {
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
};

/**
 * Middleware to check if user is a unit head
 */
const requireUnitHead = (req, res, next) => {
  const headRoles = [
    'super_admin',
    'center_head',
    'social_head',
    'medical_head',
    'psych_head',
    'rehab_head',
    'homelife_head',
  ];
  if (!headRoles.includes(req.profile?.role)) {
    return res.status(403).json({ error: 'Unit head access required' });
  }
  next();
};

module.exports = {
  verifyToken,
  requireSuperAdmin,
  requireAdmin,
  requireUnitHead,
};

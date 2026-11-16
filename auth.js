const bcrypt = require('bcryptjs');
const { pool } = require('./db');
async function loadIdentity(req, res, next) {
 try {
  if (!req.session?.userId) return res.status(401).json({ error: 'Authentication required' });
  const q = await pool.query(`SELECT u.id,u.username,u.status, COALESCE(array_agg(DISTINCT r.code) FILTER (WHERE r.code IS NOT NULL),'{}') roles, COALESCE(array_agg(DISTINCT p.code) FILTER (WHERE p.code IS NOT NULL),'{}') permissions FROM users u LEFT JOIN user_roles ur ON ur.user_id=u.id LEFT JOIN roles r ON r.id=ur.role_id LEFT JOIN role_permissions rp ON rp.role_id=r.id LEFT JOIN permissions p ON p.id=rp.permission_id WHERE u.id=$1 GROUP BY u.id`, [req.session.userId]);
  if (!q.rowCount || q.rows[0].status !== 'active') { req.session.destroy(()=>{}); return res.status(401).json({error:'Account inactive'}); }
  req.user=q.rows[0]; next();
 } catch(e){ next(e); }
}
function requirePermission(code){ return (req,res,next)=>{ if(!req.user?.permissions?.includes(code)) return res.status(403).json({error:'Permission denied',required:code}); next(); }; }
async function verifyPassword(plain, hash){ return bcrypt.compare(plain,hash); }
module.exports={loadIdentity,requirePermission,verifyPassword};

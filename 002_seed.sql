INSERT INTO roles(code,description) VALUES
('super_admin','Full platform administration'),('admin','Operational administration'),('sub_agent','Restricted sub-agent access'),('customer','Customer demo access') ON CONFLICT(code) DO NOTHING;
INSERT INTO permissions(code,description) VALUES
('dashboard.read','View admin dashboard'),('users.read','View users'),('users.create','Create users'),('users.update','Update users'),('users.suspend','Suspend or activate users'),('roles.read','View roles'),('roles.assign','Assign roles'),('sports.read','View sports fixtures'),('sports.manage','Manage demo fixtures'),('reports.read','View reports'),('audit.read','View audit logs'),('wallet.demo.read','View demo-credit balances'),('wallet.demo.adjust','Adjust demo credits'),('settings.manage','Manage platform settings') ON CONFLICT(code) DO NOTHING;
INSERT INTO role_permissions(role_id,permission_id)
SELECT r.id,p.id FROM roles r CROSS JOIN permissions p WHERE r.code='super_admin' ON CONFLICT DO NOTHING;
INSERT INTO role_permissions(role_id,permission_id)
SELECT r.id,p.id FROM roles r JOIN permissions p ON p.code IN ('dashboard.read','users.read','users.create','users.update','users.suspend','roles.read','sports.read','sports.manage','reports.read','audit.read','wallet.demo.read') WHERE r.code='admin' ON CONFLICT DO NOTHING;
INSERT INTO role_permissions(role_id,permission_id)
SELECT r.id,p.id FROM roles r JOIN permissions p ON p.code IN ('dashboard.read','sports.read','wallet.demo.read') WHERE r.code='sub_agent' ON CONFLICT DO NOTHING;
INSERT INTO sports(code,name_i18n) VALUES
('football','{"en":"Football","am":"እግር ኳስ","om":"Kubbaa miilaa"}'),
('virtual_football','{"en":"Virtual Football","am":"ቨርቹዋል እግር ኳስ","om":"Virtual Kubbaa"}'),
('horse_racing','{"en":"Horse Racing","am":"የፈረስ ውድድር","om":"Gingilchaa fardaa"}'),
('dog_racing','{"en":"Dog Racing","am":"የውሻ ውድድር","om":"Gingilchaa saree"}'),
('virtual_basketball','{"en":"Virtual Basketball","am":"ቨርቹዋል ባስኬትቦል","om":"Virtual Kubbaa harkaa"}') ON CONFLICT(code) DO NOTHING;

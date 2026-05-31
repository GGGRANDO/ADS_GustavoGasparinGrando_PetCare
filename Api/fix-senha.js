require('dotenv').config();
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});

async function fix() {
  const hash = await bcrypt.hash('123', 10);
  await pool.query('UPDATE usuarios SET senha = $1 WHERE email = $2', [hash, 'admin@petcare.com']);
  console.log('Senha corrigida! Login: admin@petcare.com / 123');
  await pool.end();
}

fix().catch(e => { console.error(e.message); pool.end(); });

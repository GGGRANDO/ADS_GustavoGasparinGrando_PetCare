require('dotenv/config');
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');

const pool = new Pool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT) || 5432,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});

async function run() {
  const client = await pool.connect();
  try {
    const hash = await bcrypt.hash('123456', 10);
    const r = await client.query(
      `INSERT INTO usuarios (nome, email, senha, perfil)
       VALUES ($1, $2, $3, 'admin')
       RETURNING id, nome, email, perfil`,
      ['Administrador', 'admin@petcare.com', hash],
    );
    console.log('Admin criado:', r.rows[0]);
  } finally {
    client.release();
    await pool.end();
  }
}

run().catch((err) => {
  console.error('Erro:', err.message);
  process.exit(1);
});

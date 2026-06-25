require('dotenv/config');
const { Pool } = require('pg');

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
    const r = await client.query(
      `UPDATE profissionais SET email = $1
       WHERE id_usuario = (SELECT id FROM usuarios WHERE email = $1)
       RETURNING id, nome, email`,
      ['gstvgrando0@gmail.com'],
    );
    if (r.rows.length === 0) {
      console.log('Nenhum profissional encontrado — tentando por id=1...');
      const r2 = await client.query(
        `UPDATE profissionais SET email = $1 WHERE id = 1 RETURNING id, nome, email`,
        ['gstvgrando0@gmail.com'],
      );
      console.log('Atualizado:', r2.rows[0]);
    } else {
      console.log('Atualizado:', r.rows[0]);
    }
  } finally {
    client.release();
    await pool.end();
  }
}

run().catch((err) => {
  console.error('Erro:', err.message);
  process.exit(1);
});

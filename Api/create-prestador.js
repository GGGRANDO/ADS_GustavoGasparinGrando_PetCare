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
    const u = await client.query(
      `INSERT INTO usuarios (nome, email, senha, perfil)
       VALUES ($1, $2, $3, 'profissional')
       RETURNING id, nome, email, perfil`,
      ['Gustavo Grando', 'gstvgrando0@gmail.com', hash],
    );
    const uid = u.rows[0].id;
    const p = await client.query(
      `INSERT INTO profissionais (nome, especialidade, id_usuario, email)
       VALUES ($1, 'Geral', $2, $3)
       RETURNING id, nome`,
      ['Gustavo Grando', uid, 'gstvgrando0@gmail.com'],
    );
    console.log('Usuário criado:', u.rows[0]);
    console.log('Profissional criado:', p.rows[0]);
  } finally {
    client.release();
    await pool.end();
  }
}

run().catch((err) => {
  console.error('Erro:', err.message);
  process.exit(1);
});

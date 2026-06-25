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
       VALUES ($1, $2, $3, 'cliente')
       RETURNING id, nome, email, perfil`,
      ['Gustavo UPF', '177641@upf.com.br', hash],
    );
    const uid = u.rows[0].id;
    const c = await client.query(
      `INSERT INTO clientes (nome, email, id_usuario)
       VALUES ($1, $2, $3)
       RETURNING id, nome`,
      ['Gustavo UPF', '177641@upf.com.br', uid],
    );
    console.log('Usuário criado:', u.rows[0]);
    console.log('Cliente criado:', c.rows[0]);
  } finally {
    client.release();
    await pool.end();
  }
}

run().catch((err) => {
  console.error('Erro:', err.message);
  process.exit(1);
});

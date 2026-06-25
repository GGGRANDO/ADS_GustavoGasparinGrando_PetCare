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
    // Limpa todas as tabelas na ordem correta (filhos antes dos pais)
    await client.query(`
      TRUNCATE TABLE
        pagamentos,
        agendamentos,
        horarios_profissional,
        servicos,
        categorias_servico,
        clientes,
        profissionais,
        password_reset_tokens,
        usuarios
      RESTART IDENTITY CASCADE;
    `);
    console.log('Banco de dados limpo com sucesso.');

    // Cria o usuário admin
    const hash = await bcrypt.hash('123456', 10);
    const r = await client.query(
      `INSERT INTO usuarios (nome, email, senha, perfil)
       VALUES ($1, $2, $3, $4)
       RETURNING id, nome, email, perfil`,
      ['Administrador', 'usuario@petcare.com', hash, 'admin'],
    );
    console.log('Usuário admin criado:', r.rows[0]);
  } finally {
    client.release();
    await pool.end();
  }
}

run().catch((err) => {
  console.error('Erro:', err.message);
  process.exit(1);
});

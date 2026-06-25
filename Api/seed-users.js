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

const SENHA = '123456';

async function upsertUsuario(client, nome, email, perfil) {
  const hash = await bcrypt.hash(SENHA, 10);
  const r = await client.query(
    `INSERT INTO usuarios (nome, email, senha, perfil)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (email) DO UPDATE SET senha = $3, perfil = $4
     RETURNING id, nome, email, perfil`,
    [nome, email, hash, perfil],
  );
  return r.rows[0];
}

async function run() {
  const client = await pool.connect();
  try {
    const admin = await upsertUsuario(client, 'Administrador', 'admin@petcare.com', 'admin');
    console.log('Admin:', admin);

    const prest = await upsertUsuario(client, 'Joao Prestador', 'prestador@petcare.com', 'profissional');
    console.log('Prestador:', prest);

    const profExiste = await client.query(
      'SELECT id FROM profissionais WHERE id_usuario = $1 OR email = $2 LIMIT 1',
      [prest.id, prest.email],
    );
    if (profExiste.rows.length > 0) {
      await client.query(
        'UPDATE profissionais SET id_usuario = $1, nome = $2 WHERE id = $3',
        [prest.id, prest.nome, profExiste.rows[0].id],
      );
    } else {
      await client.query(
        "INSERT INTO profissionais (nome, telefone, especialidade, id_usuario) VALUES ($1, '(44) 99999-1111', 'Banho e Tosa', $2)",
        [prest.nome, prest.id],
      );
    }

    const cli = await upsertUsuario(client, 'Maria Cliente', 'cliente@petcare.com', 'cliente');
    console.log('Cliente:', cli);

    const cliExiste = await client.query(
      'SELECT id FROM clientes WHERE id_usuario = $1 OR email = $2 LIMIT 1',
      [cli.id, cli.email],
    );
    if (cliExiste.rows.length > 0) {
      await client.query(
        'UPDATE clientes SET id_usuario = $1, nome = $2 WHERE id = $3',
        [cli.id, cli.nome, cliExiste.rows[0].id],
      );
    } else {
      await client.query(
        "INSERT INTO clientes (nome, email, telefone, id_usuario) VALUES ($1, $2, '(44) 99999-2222', $3)",
        [cli.nome, cli.email, cli.id],
      );
    }

    console.log('');
    console.log('Seed concluido! Senha de todos: 123456');
    console.log('  admin@petcare.com      / 123456  (admin)');
    console.log('  prestador@petcare.com  / 123456  (profissional)');
    console.log('  cliente@petcare.com    / 123456  (cliente)');
  } finally {
    client.release();
    await pool.end();
  }
}

run().catch((e) => { console.error('ERRO:', e.message); process.exit(1); });

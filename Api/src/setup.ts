import 'dotenv/config';
import { pool } from './db';

async function setup() {
  const client = await pool.connect();
  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS usuarios (
        id        SERIAL PRIMARY KEY,
        nome      VARCHAR(255) NOT NULL,
        email     VARCHAR(255) UNIQUE NOT NULL,
        senha     VARCHAR(255) NOT NULL,
        perfil    VARCHAR(50)  NOT NULL DEFAULT 'atendente',
        criado_em TIMESTAMP DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS clientes (
        id            SERIAL PRIMARY KEY,
        nome          VARCHAR(255) NOT NULL,
        telefone      VARCHAR(50),
        email         VARCHAR(255),
        observacoes   TEXT,
        status        VARCHAR(20)  DEFAULT 'ativo',
        data_cadastro TIMESTAMP    DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS profissionais (
        id             SERIAL PRIMARY KEY,
        nome           VARCHAR(255) NOT NULL,
        telefone       VARCHAR(50),
        especialidade  VARCHAR(255),
        disponibilidade TEXT,
        status         VARCHAR(20) DEFAULT 'ativo'
      );

      CREATE TABLE IF NOT EXISTS servicos (
        id        SERIAL PRIMARY KEY,
        descricao VARCHAR(255) NOT NULL,
        valor     NUMERIC(10,2),
        observacao TEXT,
        status    VARCHAR(20) DEFAULT 'ativo'
      );

      CREATE TABLE IF NOT EXISTS agendamentos (
        id               SERIAL PRIMARY KEY,
        id_cliente       INTEGER NOT NULL REFERENCES clientes(id),
        id_profissional  INTEGER NOT NULL REFERENCES profissionais(id),
        id_servico       INTEGER NOT NULL REFERENCES servicos(id),
        data_atendimento DATE    NOT NULL,
        horario          TIME    NOT NULL,
        status           VARCHAR(50) DEFAULT 'agendado',
        observacao       TEXT,
        criado_em        TIMESTAMP DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS password_reset_tokens (
        id         SERIAL PRIMARY KEY,
        email      VARCHAR(255) NOT NULL,
        token      VARCHAR(6)   NOT NULL,
        expira_em  TIMESTAMP    NOT NULL,
        usado      BOOLEAN      DEFAULT FALSE,
        criado_em  TIMESTAMP    DEFAULT NOW()
      );

      ALTER TABLE clientes
        ADD COLUMN IF NOT EXISTS id_usuario INTEGER REFERENCES usuarios(id);

      ALTER TABLE profissionais
        ADD COLUMN IF NOT EXISTS id_usuario INTEGER REFERENCES usuarios(id);
    `);
    console.log('Tabelas criadas com sucesso.');
  } finally {
    client.release();
    await pool.end();
  }
}

setup().catch((err) => {
  console.error('Erro ao criar tabelas:', err);
  process.exit(1);
});

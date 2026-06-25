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

      CREATE TABLE IF NOT EXISTS horarios_profissional (
        id              SERIAL PRIMARY KEY,
        id_profissional INTEGER  NOT NULL REFERENCES profissionais(id) ON DELETE CASCADE,
        dia_semana      SMALLINT NOT NULL CHECK (dia_semana BETWEEN 0 AND 6),
        hora_inicio     TIME     NOT NULL,
        hora_fim        TIME     NOT NULL,
        intervalo_min   SMALLINT NOT NULL DEFAULT 60,
        ativo           BOOLEAN  DEFAULT TRUE,
        UNIQUE (id_profissional, dia_semana)
      );

      ALTER TABLE servicos
        ADD COLUMN IF NOT EXISTS duracao_min   SMALLINT DEFAULT 60;

      ALTER TABLE servicos
        ADD COLUMN IF NOT EXISTS id_profissional INTEGER REFERENCES profissionais(id);

      ALTER TABLE clientes
        ADD COLUMN IF NOT EXISTS id_usuario INTEGER REFERENCES usuarios(id);

      ALTER TABLE profissionais
        ADD COLUMN IF NOT EXISTS id_usuario INTEGER REFERENCES usuarios(id);

      ALTER TABLE profissionais
        ADD COLUMN IF NOT EXISTS email VARCHAR(255);

      ALTER TABLE clientes
        ADD COLUMN IF NOT EXISTS cpf_cnpj VARCHAR(20);

      ALTER TABLE agendamentos
        ADD COLUMN IF NOT EXISTS motivo_cancelamento TEXT;

      CREATE TABLE IF NOT EXISTS categorias_servico (
        id        SERIAL PRIMARY KEY,
        nome      VARCHAR(255) NOT NULL UNIQUE,
        descricao TEXT,
        status    VARCHAR(20) DEFAULT 'ativo',
        criado_em TIMESTAMP DEFAULT NOW()
      );

      ALTER TABLE servicos
        ADD COLUMN IF NOT EXISTS id_categoria INTEGER REFERENCES categorias_servico(id);

      CREATE TABLE IF NOT EXISTS pagamentos (
        id                   SERIAL PRIMARY KEY,
        id_agendamento       INTEGER NOT NULL REFERENCES agendamentos(id) ON DELETE CASCADE,
        asaas_customer_id    VARCHAR(100),
        asaas_payment_id     VARCHAR(100) UNIQUE,
        valor                NUMERIC(10,2) NOT NULL,
        forma_pagamento      VARCHAR(30)  NOT NULL DEFAULT 'PIX',
        status               VARCHAR(50)  NOT NULL DEFAULT 'PENDING',
        pix_copia_cola       TEXT,
        pix_expiracao        TIMESTAMP,
        link_boleto          TEXT,
        link_fatura          TEXT,
        criado_em            TIMESTAMP DEFAULT NOW(),
        atualizado_em        TIMESTAMP DEFAULT NOW()
      );
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

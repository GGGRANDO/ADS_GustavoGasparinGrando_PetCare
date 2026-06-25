import { Router, Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import nodemailer from 'nodemailer';
import crypto from 'crypto';
import { pool } from '../db';
import { createTransporter } from '../mailer';

const router = Router();

const PERFIS_VALIDOS = ['cliente', 'profissional', 'atendente', 'admin'];

// POST /api/auth/register
router.post('/register', async (req: Request, res: Response) => {
  const { nome, email, senha, perfil, telefone, especialidade } = req.body as {
    nome: string;
    email: string;
    senha: string;
    perfil?: string;
    telefone?: string;
    especialidade?: string;
  };

  if (!nome || !email || !senha) {
    res.status(400).json({ error: 'nome, email e senha são obrigatórios.' });
    return;
  }

  const perfilFinal = perfil && PERFIS_VALIDOS.includes(perfil) ? perfil : 'cliente';

  const dbClient = await pool.connect();
  try {
    await dbClient.query('BEGIN');

    const hash = await bcrypt.hash(senha, 10);
    const result = await dbClient.query(
      `INSERT INTO usuarios (nome, email, senha, perfil)
       VALUES ($1, $2, $3, $4)
       RETURNING id, nome, email, perfil`,
      [nome, email, hash, perfilFinal],
    );
    const usuario = result.rows[0];

    if (perfilFinal === 'cliente') {
      await dbClient.query(
        `INSERT INTO clientes (nome, email, telefone, id_usuario)
         VALUES ($1, $2, $3, $4)`,
        [nome, email, telefone || null, usuario.id],
      );
    } else if (perfilFinal === 'profissional') {
      await dbClient.query(
        `INSERT INTO profissionais (nome, telefone, especialidade, id_usuario)
         VALUES ($1, $2, $3, $4)`,
        [nome, telefone || null, especialidade || null, usuario.id],
      );
    }

    await dbClient.query('COMMIT');
    res.status(201).json(usuario);
  } catch (err: unknown) {
    await dbClient.query('ROLLBACK');
    const pg = err as { code?: string };
    if (pg.code === '23505') {
      res.status(409).json({ error: 'E-mail já cadastrado.' });
    } else {
      console.error(err);
      res.status(500).json({ error: 'Erro interno.' });
    }
  } finally {
    dbClient.release();
  }
});

// POST /api/auth/login
router.post('/login', async (req: Request, res: Response) => {
  const { email, senha } = req.body as { email: string; senha: string };

  if (!email || !senha) {
    res.status(400).json({ error: 'email e senha são obrigatórios.' });
    return;
  }

  try {
    const result = await pool.query(
      'SELECT id, nome, email, senha, perfil FROM usuarios WHERE email = $1',
      [email],
    );

    if (result.rows.length === 0) {
      res.status(401).json({ error: 'Credenciais inválidas.' });
      return;
    }

    const usuario = result.rows[0];
    const senhaOk = await bcrypt.compare(senha, usuario.senha);

    if (!senhaOk) {
      res.status(401).json({ error: 'Credenciais inválidas.' });
      return;
    }

    const secret = process.env.JWT_SECRET || 'petcare_secret_change_in_production';
    const token = jwt.sign(
      { id: usuario.id, perfil: usuario.perfil },
      secret,
      { expiresIn: '8h' },
    );

    // Busca id vinculado na tabela clientes ou profissionais
    let idVinculado: number | null = null;
    if (usuario.perfil === 'cliente') {
      let r = await pool.query('SELECT id FROM clientes WHERE id_usuario = $1', [usuario.id]);
      if (r.rows.length > 0) {
        idVinculado = r.rows[0].id;
      } else {
        // Fallback: cliente cadastrado pelo admin sem id_usuario — vincula pelo e-mail
        r = await pool.query('SELECT id FROM clientes WHERE email = $1 ORDER BY id LIMIT 1', [usuario.email]);
        if (r.rows.length > 0) {
          idVinculado = r.rows[0].id;
          // Atualiza o vínculo para os próximos logins
          await pool.query('UPDATE clientes SET id_usuario = $1 WHERE id = $2', [usuario.id, idVinculado]);
        }
      }
    } else if (usuario.perfil === 'profissional') {
      let r = await pool.query('SELECT id FROM profissionais WHERE id_usuario = $1', [usuario.id]);
      if (r.rows.length > 0) {
        idVinculado = r.rows[0].id;
      } else {
        // Fallback: profissional sem id_usuario — vincula pelo e-mail
        r = await pool.query('SELECT id FROM profissionais WHERE email = $1 ORDER BY id LIMIT 1', [usuario.email]);
        if (r.rows.length > 0) {
          idVinculado = r.rows[0].id;
          await pool.query('UPDATE profissionais SET id_usuario = $1 WHERE id = $2', [usuario.id, idVinculado]);
        }
      }
    }

    res.json({
      token,
      usuario: {
        id: usuario.id,
        nome: usuario.nome,
        email: usuario.email,
        perfil: usuario.perfil,
        id_vinculado: idVinculado,
      },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

// POST /api/auth/forgot-password
router.post('/forgot-password', async (req: Request, res: Response) => {
  const { email } = req.body as { email: string };

  if (!email) {
    res.status(400).json({ error: 'E-mail é obrigatório.' });
    return;
  }

  try {
    const result = await pool.query(
      'SELECT id, nome FROM usuarios WHERE email = $1',
      [email],
    );

    // Responde sempre com sucesso para não revelar quais e-mails estão cadastrados
    if (result.rows.length === 0) {
      res.json({ message: 'Se o e-mail estiver cadastrado, você receberá as instruções.' });
      return;
    }

    const usuario = result.rows[0];

    // Gera token numérico de 6 dígitos
    const token = crypto.randomInt(100000, 999999).toString();
    const expiraEm = new Date(Date.now() + 15 * 60 * 1000); // 15 minutos

    // Invalida tokens anteriores do mesmo e-mail
    await pool.query(
      'UPDATE password_reset_tokens SET usado = TRUE WHERE email = $1 AND usado = FALSE',
      [email],
    );

    await pool.query(
      'INSERT INTO password_reset_tokens (email, token, expira_em) VALUES ($1, $2, $3)',
      [email, token, expiraEm],
    );

    try {
      const { transport, isTest } = await createTransporter();
      const info = await transport.sendMail({
        from: process.env.SMTP_FROM || 'PetCare <noreply@petcare.com>',
        to: email,
        subject: 'Redefinição de senha — PetCare',
        html: `
          <div style="font-family:Arial,sans-serif;max-width:480px;margin:0 auto">
            <h2 style="color:#008080">PetCare 🐾</h2>
            <p>Olá, <strong>${usuario.nome}</strong>!</p>
            <p>Recebemos uma solicitação de redefinição de senha para sua conta.</p>
            <p>Use o código abaixo no aplicativo. Ele é válido por <strong>15 minutos</strong>:</p>
            <div style="font-size:36px;font-weight:bold;letter-spacing:8px;text-align:center;
                        background:#f0f0f0;padding:16px 24px;border-radius:8px;margin:24px 0">
              ${token}
            </div>
            <p style="color:#888;font-size:12px">
              Se você não solicitou a redefinição, ignore este e-mail.
            </p>
          </div>
        `,
      });

      if (isTest) {
        // Modo desenvolvimento: exibe link do Ethereal e o token no console
        console.log(`[DEV] Preview do e-mail: ${nodemailer.getTestMessageUrl(info)}`);
        console.log(`[DEV] Token para ${email}: ${token}`);
      }
    } catch (mailErr) {
      // Falha no envio não deve expor erro ao cliente nem bloquear o fluxo;
      // o token já foi salvo e pode ser reusado.
      console.error('[SMTP] Falha ao enviar e-mail de redefinição:', mailErr);
    }

    res.json({ message: 'Se o e-mail estiver cadastrado, você receberá as instruções.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

// POST /api/auth/reset-password
router.post('/reset-password', async (req: Request, res: Response) => {
  const { email, token, novaSenha } = req.body as {
    email: string;
    token: string;
    novaSenha: string;
  };

  if (!email || !token || !novaSenha) {
    res.status(400).json({ error: 'email, token e novaSenha são obrigatórios.' });
    return;
  }

  if (novaSenha.length < 6) {
    res.status(400).json({ error: 'A nova senha deve ter pelo menos 6 caracteres.' });
    return;
  }

  try {
    const result = await pool.query(
      `SELECT id FROM password_reset_tokens
       WHERE email = $1 AND token = $2 AND usado = FALSE AND expira_em > NOW()`,
      [email, token],
    );

    if (result.rows.length === 0) {
      res.status(400).json({ error: 'Código inválido ou expirado.' });
      return;
    }

    const hash = await bcrypt.hash(novaSenha, 10);
    await pool.query('UPDATE usuarios SET senha = $1 WHERE email = $2', [hash, email]);

    // Marca o token como usado
    await pool.query(
      'UPDATE password_reset_tokens SET usado = TRUE WHERE id = $1',
      [result.rows[0].id],
    );

    res.json({ message: 'Senha redefinida com sucesso.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

export default router;

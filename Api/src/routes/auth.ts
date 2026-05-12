import { Router, Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { pool } from '../db';

const router = Router();

// POST /api/auth/register
router.post('/register', async (req: Request, res: Response) => {
  const { nome, email, senha, perfil } = req.body as {
    nome: string;
    email: string;
    senha: string;
    perfil?: string;
  };

  if (!nome || !email || !senha) {
    res.status(400).json({ error: 'nome, email e senha são obrigatórios.' });
    return;
  }

  try {
    const hash = await bcrypt.hash(senha, 10);
    const result = await pool.query(
      `INSERT INTO usuarios (nome, email, senha, perfil)
       VALUES ($1, $2, $3, $4)
       RETURNING id, nome, email, perfil`,
      [nome, email, hash, perfil || 'atendente'],
    );
    res.status(201).json(result.rows[0]);
  } catch (err: unknown) {
    const pg = err as { code?: string };
    if (pg.code === '23505') {
      res.status(409).json({ error: 'E-mail já cadastrado.' });
    } else {
      console.error(err);
      res.status(500).json({ error: 'Erro interno.' });
    }
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

    res.json({
      token,
      usuario: { id: usuario.id, nome: usuario.nome, email: usuario.email, perfil: usuario.perfil },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

export default router;

import { Router, Response } from 'express';
import { pool } from '../db';
import { authMiddleware, AuthRequest } from '../middlewares/auth';

const router = Router();
router.use(authMiddleware);

// GET /api/clientes
router.get('/', async (_req: AuthRequest, res: Response) => {
  try {
    const result = await pool.query(
      'SELECT * FROM clientes ORDER BY nome ASC',
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

// GET /api/clientes/meu-perfil  — perfil do cliente autenticado (usa JWT)
router.get('/meu-perfil', async (req: AuthRequest, res: Response) => {
  try {
    // Primeiro tenta pelo id_usuario vindo do JWT
    let result = await pool.query(
      'SELECT * FROM clientes WHERE id_usuario = $1',
      [req.userId],
    );

    if (result.rows.length === 0) {
      // Fallback: busca pelo e-mail do usuário e vincula
      const userResult = await pool.query(
        'SELECT email FROM usuarios WHERE id = $1',
        [req.userId],
      );
      if (userResult.rows.length > 0) {
        const email = userResult.rows[0].email as string;
        result = await pool.query(
          'SELECT * FROM clientes WHERE email = $1 ORDER BY id LIMIT 1',
          [email],
        );
        if (result.rows.length > 0) {
          await pool.query(
            'UPDATE clientes SET id_usuario = $1 WHERE id = $2',
            [req.userId, result.rows[0].id],
          );
        }
      }
    }

    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Perfil de cliente não encontrado.' });
      return;
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

// GET /api/clientes/:id
router.get('/:id', async (req: AuthRequest, res: Response) => {
  try {
    const result = await pool.query(
      'SELECT * FROM clientes WHERE id = $1',
      [req.params.id],
    );
    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Cliente não encontrado.' });
      return;
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

// POST /api/clientes
router.post('/', async (req: AuthRequest, res: Response) => {
  const { nome, telefone, email, observacoes } = req.body as {
    nome: string;
    telefone?: string;
    email?: string;
    observacoes?: string;
  };

  if (!nome) {
    res.status(400).json({ error: 'nome é obrigatório.' });
    return;
  }

  try {
    const result = await pool.query(
      `INSERT INTO clientes (nome, telefone, email, observacoes)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [nome, telefone || null, email || null, observacoes || null],
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

// PUT /api/clientes/:id
router.put('/:id', async (req: AuthRequest, res: Response) => {
  const { nome, telefone, email, observacoes, status } = req.body as {
    nome?: string;
    telefone?: string;
    email?: string;
    observacoes?: string;
    status?: string;
  };

  try {
    const result = await pool.query(
      `UPDATE clientes
       SET nome        = COALESCE($1, nome),
           telefone    = COALESCE($2, telefone),
           email       = COALESCE($3, email),
           observacoes = COALESCE($4, observacoes),
           status      = COALESCE($5, status)
       WHERE id = $6
       RETURNING *`,
      [nome, telefone, email, observacoes, status, req.params.id],
    );
    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Cliente não encontrado.' });
      return;
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

// DELETE /api/clientes/:id  — bloqueia se houver agendamentos
router.delete('/:id', async (req: AuthRequest, res: Response) => {
  try {
    const agCheck = await pool.query(
      'SELECT id FROM agendamentos WHERE id_cliente = $1 LIMIT 1',
      [req.params.id],
    );
    if (agCheck.rows.length > 0) {
      res.status(409).json({
        error: 'Cliente possui agendamentos. Use inativação em vez de exclusão.',
      });
      return;
    }
    await pool.query('DELETE FROM clientes WHERE id = $1', [req.params.id]);
    res.status(204).send();
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

export default router;

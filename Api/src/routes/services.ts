import { Router, Response } from 'express';
import { pool } from '../db';
import { authMiddleware, AuthRequest } from '../middlewares/auth';

const router = Router();
router.use(authMiddleware);

// GET /api/servicos
router.get('/', async (_req: AuthRequest, res: Response) => {
  try {
    const result = await pool.query('SELECT * FROM servicos ORDER BY descricao ASC');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

// GET /api/servicos/:id
router.get('/:id', async (req: AuthRequest, res: Response) => {
  try {
    const result = await pool.query(
      'SELECT * FROM servicos WHERE id = $1',
      [req.params.id],
    );
    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Serviço não encontrado.' });
      return;
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

// POST /api/servicos
router.post('/', async (req: AuthRequest, res: Response) => {
  const { descricao, valor, observacao } = req.body as {
    descricao: string;
    valor?: number;
    observacao?: string;
  };

  if (!descricao) {
    res.status(400).json({ error: 'descricao é obrigatória.' });
    return;
  }

  try {
    const result = await pool.query(
      `INSERT INTO servicos (descricao, valor, observacao)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [descricao, valor ?? null, observacao || null],
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

// PUT /api/servicos/:id
router.put('/:id', async (req: AuthRequest, res: Response) => {
  const { descricao, valor, observacao, status } = req.body as {
    descricao?: string;
    valor?: number;
    observacao?: string;
    status?: string;
  };

  try {
    const result = await pool.query(
      `UPDATE servicos
       SET descricao  = COALESCE($1, descricao),
           valor      = COALESCE($2, valor),
           observacao = COALESCE($3, observacao),
           status     = COALESCE($4, status)
       WHERE id = $5
       RETURNING *`,
      [descricao, valor ?? null, observacao, status, req.params.id],
    );
    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Serviço não encontrado.' });
      return;
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

// DELETE /api/servicos/:id  — bloqueia se houver agendamentos
router.delete('/:id', async (req: AuthRequest, res: Response) => {
  try {
    const agCheck = await pool.query(
      'SELECT id FROM agendamentos WHERE id_servico = $1 LIMIT 1',
      [req.params.id],
    );
    if (agCheck.rows.length > 0) {
      res.status(409).json({
        error: 'Serviço possui agendamentos. Use inativação em vez de exclusão.',
      });
      return;
    }
    await pool.query('DELETE FROM servicos WHERE id = $1', [req.params.id]);
    res.status(204).send();
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

export default router;

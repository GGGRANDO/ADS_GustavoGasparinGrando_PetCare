import { Router, Response } from 'express';
import { pool } from '../db';
import { authMiddleware, AuthRequest } from '../middlewares/auth';

const router = Router();
router.use(authMiddleware);

// GET /api/categorias
router.get('/', async (_req: AuthRequest, res: Response) => {
  try {
    const result = await pool.query(
      `SELECT * FROM categorias_servico ORDER BY nome ASC`,
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

// GET /api/categorias/:id
router.get('/:id', async (req: AuthRequest, res: Response) => {
  try {
    const result = await pool.query(
      `SELECT * FROM categorias_servico WHERE id = $1`,
      [req.params.id],
    );
    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Categoria não encontrada.' });
      return;
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

// POST /api/categorias
router.post('/', async (req: AuthRequest, res: Response) => {
  const { nome, descricao } = req.body as { nome: string; descricao?: string };
  if (!nome?.trim()) {
    res.status(400).json({ error: 'nome é obrigatório.' });
    return;
  }
  try {
    const result = await pool.query(
      `INSERT INTO categorias_servico (nome, descricao) VALUES ($1, $2) RETURNING *`,
      [nome.trim(), descricao || null],
    );
    res.status(201).json(result.rows[0]);
  } catch (err: unknown) {
    const pg = err as { code?: string };
    if (pg.code === '23505') {
      res.status(409).json({ error: 'Já existe uma categoria com esse nome.' });
      return;
    }
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

// PUT /api/categorias/:id
router.put('/:id', async (req: AuthRequest, res: Response) => {
  const { nome, descricao, status } = req.body as {
    nome?: string;
    descricao?: string;
    status?: string;
  };
  try {
    const result = await pool.query(
      `UPDATE categorias_servico
       SET nome      = COALESCE($1, nome),
           descricao = COALESCE($2, descricao),
           status    = COALESCE($3, status)
       WHERE id = $4
       RETURNING *`,
      [nome ?? null, descricao ?? null, status ?? null, req.params.id],
    );
    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Categoria não encontrada.' });
      return;
    }
    res.json(result.rows[0]);
  } catch (err: unknown) {
    const pg = err as { code?: string };
    if (pg.code === '23505') {
      res.status(409).json({ error: 'Já existe uma categoria com esse nome.' });
      return;
    }
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

// DELETE /api/categorias/:id
router.delete('/:id', async (req: AuthRequest, res: Response) => {
  try {
    const inUse = await pool.query(
      `SELECT id FROM servicos WHERE id_categoria = $1 LIMIT 1`,
      [req.params.id],
    );
    if (inUse.rows.length > 0) {
      res.status(409).json({
        error: 'Categoria possui serviços vinculados. Remova os serviços antes.',
      });
      return;
    }
    await pool.query(`DELETE FROM categorias_servico WHERE id = $1`, [req.params.id]);
    res.status(204).send();
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

export default router;

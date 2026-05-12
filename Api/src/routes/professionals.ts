import { Router, Response } from 'express';
import { pool } from '../db';
import { authMiddleware, AuthRequest } from '../middlewares/auth';

const router = Router();
router.use(authMiddleware);

// GET /api/profissionais
router.get('/', async (_req: AuthRequest, res: Response) => {
  try {
    const result = await pool.query(
      'SELECT * FROM profissionais ORDER BY nome ASC',
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

// GET /api/profissionais/:id
router.get('/:id', async (req: AuthRequest, res: Response) => {
  try {
    const result = await pool.query(
      'SELECT * FROM profissionais WHERE id = $1',
      [req.params.id],
    );
    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Profissional não encontrado.' });
      return;
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

// POST /api/profissionais
router.post('/', async (req: AuthRequest, res: Response) => {
  const { nome, telefone, especialidade, disponibilidade } = req.body as {
    nome: string;
    telefone?: string;
    especialidade?: string;
    disponibilidade?: string;
  };

  if (!nome) {
    res.status(400).json({ error: 'nome é obrigatório.' });
    return;
  }

  try {
    const result = await pool.query(
      `INSERT INTO profissionais (nome, telefone, especialidade, disponibilidade)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [nome, telefone || null, especialidade || null, disponibilidade || null],
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

// PUT /api/profissionais/:id
router.put('/:id', async (req: AuthRequest, res: Response) => {
  const { nome, telefone, especialidade, disponibilidade, status } = req.body as {
    nome?: string;
    telefone?: string;
    especialidade?: string;
    disponibilidade?: string;
    status?: string;
  };

  try {
    const result = await pool.query(
      `UPDATE profissionais
       SET nome            = COALESCE($1, nome),
           telefone        = COALESCE($2, telefone),
           especialidade   = COALESCE($3, especialidade),
           disponibilidade = COALESCE($4, disponibilidade),
           status          = COALESCE($5, status)
       WHERE id = $6
       RETURNING *`,
      [nome, telefone, especialidade, disponibilidade, status, req.params.id],
    );
    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Profissional não encontrado.' });
      return;
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

// DELETE /api/profissionais/:id  — bloqueia se houver agendamentos
router.delete('/:id', async (req: AuthRequest, res: Response) => {
  try {
    const agCheck = await pool.query(
      'SELECT id FROM agendamentos WHERE id_profissional = $1 LIMIT 1',
      [req.params.id],
    );
    if (agCheck.rows.length > 0) {
      res.status(409).json({
        error: 'Profissional possui agendamentos. Use inativação em vez de exclusão.',
      });
      return;
    }
    await pool.query('DELETE FROM profissionais WHERE id = $1', [req.params.id]);
    res.status(204).send();
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

export default router;

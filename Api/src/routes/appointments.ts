import { Router, Response } from 'express';
import { pool } from '../db';
import { authMiddleware, AuthRequest } from '../middlewares/auth';
import { enviarNotificacaoAgendamento } from '../mailer';

const router = Router();
router.use(authMiddleware);

// GET /api/agendamentos?data=YYYY-MM-DD&id_profissional=&id_cliente=&status=
router.get('/', async (req: AuthRequest, res: Response) => {
  const { data, id_profissional, id_cliente, status } = req.query as Record<string, string | undefined>;

  try {
    const conditions: string[] = [];
    const values: unknown[] = [];

    if (data) {
      values.push(data);
      conditions.push(`a.data_atendimento = $${values.length}`);
    }
    if (id_profissional) {
      values.push(id_profissional);
      conditions.push(`a.id_profissional = $${values.length}`);
    }
    if (id_cliente) {
      values.push(id_cliente);
      conditions.push(`a.id_cliente = $${values.length}`);
    }
    if (status) {
      values.push(status);
      conditions.push(`a.status = $${values.length}`);
    }

    const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

    const result = await pool.query(
      `SELECT a.*,
              c.nome AS cliente_nome,
              p.nome AS profissional_nome,
              s.descricao AS servico_descricao
       FROM agendamentos a
       JOIN clientes      c ON c.id = a.id_cliente
       JOIN profissionais p ON p.id = a.id_profissional
       JOIN servicos      s ON s.id = a.id_servico
       ${where}
       ORDER BY a.data_atendimento ASC, a.horario ASC`,
      values,
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

// GET /api/agendamentos/:id
router.get('/:id', async (req: AuthRequest, res: Response) => {
  try {
    const result = await pool.query(
      `SELECT a.*,
              c.nome AS cliente_nome,
              p.nome AS profissional_nome,
              s.descricao AS servico_descricao
       FROM agendamentos a
       JOIN clientes      c ON c.id = a.id_cliente
       JOIN profissionais p ON p.id = a.id_profissional
       JOIN servicos      s ON s.id = a.id_servico
       WHERE a.id = $1`,
      [req.params.id],
    );
    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Agendamento não encontrado.' });
      return;
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

// POST /api/agendamentos  — verifica conflito de horário
router.post('/', async (req: AuthRequest, res: Response) => {
  const { id_cliente, id_profissional, id_servico, data_atendimento, horario, observacao } =
    req.body as {
      id_cliente: number;
      id_profissional: number;
      id_servico: number;
      data_atendimento: string;
      horario: string;
      observacao?: string;
    };

  if (!id_cliente || !id_profissional || !id_servico || !data_atendimento || !horario) {
    res.status(400).json({
      error: 'id_cliente, id_profissional, id_servico, data_atendimento e horario são obrigatórios.',
    });
    return;
  }

  try {
    // Verifica conflito de horário para o mesmo profissional
    const conflict = await pool.query(
      `SELECT id FROM agendamentos
       WHERE id_profissional = $1
         AND data_atendimento = $2
         AND horario = $3
         AND status NOT IN ('cancelado')`,
      [id_profissional, data_atendimento, horario],
    );

    if (conflict.rows.length > 0) {
      res.status(409).json({
        error: 'Profissional já possui agendamento nesse horário.',
      });
      return;
    }

    const result = await pool.query(
      `INSERT INTO agendamentos
         (id_cliente, id_profissional, id_servico, data_atendimento, horario, observacao)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [id_cliente, id_profissional, id_servico, data_atendimento, horario, observacao || null],
    );

    res.status(201).json(result.rows[0]);

    // Envia notificação por email ao prestador de serviço (sem bloquear a resposta)
    try {
      const infoResult = await pool.query(
        `SELECT p.email AS profissional_email,
                p.nome  AS profissional_nome,
                c.nome  AS cliente_nome,
                s.descricao AS servico_descricao
         FROM profissionais p
         JOIN clientes      c ON c.id = $2
         JOIN servicos      s ON s.id = $3
         WHERE p.id = $1`,
        [id_profissional, id_cliente, id_servico],
      );

      const info = infoResult.rows[0];
      if (info?.profissional_email) {
        await enviarNotificacaoAgendamento({
          profissionalEmail: info.profissional_email,
          profissionalNome: info.profissional_nome,
          clienteNome: info.cliente_nome,
          servicoDescricao: info.servico_descricao,
          dataAtendimento: data_atendimento,
          horario,
          observacao,
        });
      }
    } catch (mailErr) {
      // Falha no email não deve reverter o agendamento já criado
      console.error('Erro ao enviar e-mail de notificação:', mailErr);
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

// PUT /api/agendamentos/:id
router.put('/:id', async (req: AuthRequest, res: Response) => {
  const { id_cliente, id_profissional, id_servico, data_atendimento, horario, status, observacao } =
    req.body as {
      id_cliente?: number;
      id_profissional?: number;
      id_servico?: number;
      data_atendimento?: string;
      horario?: string;
      status?: string;
      observacao?: string;
    };

  try {
    // If changing time/professional, check conflict excluding current record
    if ((data_atendimento || horario) && id_profissional) {
      const conflict = await pool.query(
        `SELECT id FROM agendamentos
         WHERE id_profissional = $1
           AND data_atendimento = $2
           AND horario = $3
           AND status NOT IN ('cancelado')
           AND id <> $4`,
        [id_profissional, data_atendimento, horario, req.params.id],
      );
      if (conflict.rows.length > 0) {
        res.status(409).json({
          error: 'Profissional já possui agendamento nesse horário.',
        });
        return;
      }
    }

    const result = await pool.query(
      `UPDATE agendamentos
       SET id_cliente       = COALESCE($1, id_cliente),
           id_profissional  = COALESCE($2, id_profissional),
           id_servico       = COALESCE($3, id_servico),
           data_atendimento = COALESCE($4, data_atendimento),
           horario          = COALESCE($5, horario),
           status           = COALESCE($6, status),
           observacao       = COALESCE($7, observacao)
       WHERE id = $8
       RETURNING *`,
      [id_cliente, id_profissional, id_servico, data_atendimento, horario, status, observacao, req.params.id],
    );
    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Agendamento não encontrado.' });
      return;
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

// DELETE /api/agendamentos/:id
router.delete('/:id', async (req: AuthRequest, res: Response) => {
  try {
    await pool.query('DELETE FROM agendamentos WHERE id = $1', [req.params.id]);
    res.status(204).send();
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

export default router;

import { Router, Response } from 'express';
import { pool } from '../db';
import { authMiddleware, AuthRequest } from '../middlewares/auth';
import {
  enviarNotificacaoAgendamento,
  enviarConfirmacaoParaCliente,
  enviarCancelamentoParaCliente,
  enviarCancelamentoParaPrestador,
} from '../mailer';

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
    // Busca duração do serviço solicitado
    const svcResult = await pool.query(
      `SELECT COALESCE(duracao_min, 60) AS duracao_min FROM servicos WHERE id = $1`,
      [id_servico],
    );
    if (svcResult.rows.length === 0) {
      res.status(404).json({ error: 'Serviço não encontrado.' });
      return;
    }
    const novaDuracao = svcResult.rows[0].duracao_min as number;

    // Verifica conflito de sobreposição para o mesmo profissional
    // Um slot conflita se o intervalo [horario, horario+duracao) se sobrepõe
    // com qualquer agendamento existente [h_existente, h_existente+duracao_existente)
    const conflict = await pool.query(
      `SELECT a.id
       FROM agendamentos a
       JOIN servicos s ON s.id = a.id_servico
       WHERE a.id_profissional = $1
         AND a.data_atendimento = $2
         AND a.status NOT IN ('cancelado')
         AND (
           -- novo início cai dentro do intervalo existente
           $3::time < (a.horario + COALESCE(s.duracao_min,60) * interval '1 minute')
           AND
           -- fim novo cai depois do início existente
           (a.horario) < ($3::time + $4 * interval '1 minute')
         )`,
      [id_profissional, data_atendimento, horario, novaDuracao],
    );

    if (conflict.rows.length > 0) {
      res.status(409).json({
        error: 'Conflito de horário: o profissional já possui um atendimento nesse período.',
      });
      return;
    }

    const result = await pool.query(
      `INSERT INTO agendamentos
         (id_cliente, id_profissional, id_servico, data_atendimento, horario, observacao, status)
       VALUES ($1, $2, $3, $4, $5, $6, 'aguardando_confirmacao')
       RETURNING *`,
      [id_cliente, id_profissional, id_servico, data_atendimento, horario, observacao || null],
    );

    res.status(201).json(result.rows[0]);

    // Envia notificação por email ao prestador de serviço (sem bloquear a resposta)
    try {
      const infoResult = await pool.query(
        `SELECT COALESCE(p.email, u.email) AS profissional_email,
                p.nome  AS profissional_nome,
                c.nome  AS cliente_nome,
                s.descricao AS servico_descricao
         FROM profissionais p
         LEFT JOIN usuarios u ON u.id = p.id_usuario
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
    // If changing time/professional/service, check overlap conflict excluding current record
    if (data_atendimento && horario && id_profissional) {
      const svcId = id_servico ?? (
        await pool.query(`SELECT id_servico FROM agendamentos WHERE id = $1`, [req.params.id])
      ).rows[0]?.id_servico;

      const svcResult = await pool.query(
        `SELECT COALESCE(duracao_min, 60) AS duracao_min FROM servicos WHERE id = $1`,
        [svcId],
      );
      const novaDuracao = (svcResult.rows[0]?.duracao_min as number) ?? 60;

      const conflict = await pool.query(
        `SELECT a.id
         FROM agendamentos a
         JOIN servicos s ON s.id = a.id_servico
         WHERE a.id_profissional = $1
           AND a.data_atendimento = $2
           AND a.status NOT IN ('cancelado')
           AND a.id <> $5
           AND (
             $3::time < (a.horario + COALESCE(s.duracao_min,60) * interval '1 minute')
             AND
             (a.horario) < ($3::time + $4 * interval '1 minute')
           )`,
        [id_profissional, data_atendimento, horario, novaDuracao, req.params.id],
      );
      if (conflict.rows.length > 0) {
        res.status(409).json({
          error: 'Conflito de horário: o profissional já possui um atendimento nesse período.',
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

// PATCH /api/agendamentos/:id/confirmar  — profissional confirma
router.patch('/:id/confirmar', async (req: AuthRequest, res: Response) => {
  try {
    const result = await pool.query(
      `UPDATE agendamentos SET status = 'confirmado' WHERE id = $1 RETURNING *`,
      [req.params.id],
    );
    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Agendamento não encontrado.' });
      return;
    }
    const ag = result.rows[0];
    res.json(ag);

    // Envia e-mail de confirmação para o cliente
    try {
      const infoResult = await pool.query(
        `SELECT COALESCE(c.email, uc.email) AS cliente_email,
                c.nome   AS cliente_nome,
                p.nome   AS profissional_nome,
                s.descricao AS servico_descricao
         FROM agendamentos a
         JOIN clientes      c  ON c.id = a.id_cliente
         LEFT JOIN usuarios uc ON uc.id = c.id_usuario
         JOIN profissionais p  ON p.id = a.id_profissional
         JOIN servicos      s  ON s.id = a.id_servico
         WHERE a.id = $1`,
        [req.params.id],
      );
      const info = infoResult.rows[0];
      if (info?.cliente_email) {
        await enviarConfirmacaoParaCliente({
          clienteEmail: info.cliente_email,
          clienteNome: info.cliente_nome,
          profissionalNome: info.profissional_nome,
          servicoDescricao: info.servico_descricao,
          dataAtendimento: ag.data_atendimento,
          horario: ag.horario,
        });
      }
    } catch (mailErr) {
      console.error('Erro ao enviar e-mail de confirmação:', mailErr);
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

// PATCH /api/agendamentos/:id/cancelar  — cancela com motivo opcional
router.patch('/:id/cancelar', async (req: AuthRequest, res: Response) => {
  const { motivo } = req.body as { motivo?: string };

  try {
    const result = await pool.query(
      `UPDATE agendamentos
       SET status = 'cancelado', motivo_cancelamento = $1
       WHERE id = $2
       RETURNING *`,
      [motivo || null, req.params.id],
    );
    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Agendamento não encontrado.' });
      return;
    }
    const ag = result.rows[0];
    res.json(ag);

    // Envia e-mail de cancelamento para o cliente
    try {
      const infoResult = await pool.query(
        `SELECT COALESCE(c.email, uc.email)  AS cliente_email,
                c.nome   AS cliente_nome,
                p.nome   AS profissional_nome,
                COALESCE(p.email, up.email)  AS profissional_email,
                s.descricao AS servico_descricao
         FROM agendamentos a
         JOIN clientes      c  ON c.id = a.id_cliente
         LEFT JOIN usuarios uc ON uc.id = c.id_usuario
         JOIN profissionais p  ON p.id = a.id_profissional
         LEFT JOIN usuarios up ON up.id = p.id_usuario
         JOIN servicos      s  ON s.id = a.id_servico
         WHERE a.id = $1`,
        [req.params.id],
      );
      const info = infoResult.rows[0];
      if (info?.cliente_email) {
        await enviarCancelamentoParaCliente({
          clienteEmail: info.cliente_email,
          clienteNome: info.cliente_nome,
          profissionalNome: info.profissional_nome,
          servicoDescricao: info.servico_descricao,
          dataAtendimento: ag.data_atendimento,
          horario: ag.horario,
          motivo,
        });
      }
      if (info?.profissional_email) {
        await enviarCancelamentoParaPrestador({
          profissionalEmail: info.profissional_email,
          profissionalNome: info.profissional_nome,
          clienteNome: info.cliente_nome,
          servicoDescricao: info.servico_descricao,
          dataAtendimento: ag.data_atendimento,
          horario: ag.horario,
          motivo,
        });
      }
    } catch (mailErr) {
      console.error('Erro ao enviar e-mail de cancelamento:', mailErr);
    }
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

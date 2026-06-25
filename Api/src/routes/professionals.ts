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

// GET /api/profissionais/meu-perfil  — perfil do profissional autenticado (usa JWT)
router.get('/meu-perfil', async (req: AuthRequest, res: Response) => {
  try {
    let result = await pool.query(
      'SELECT * FROM profissionais WHERE id_usuario = $1',
      [req.userId],
    );

    if (result.rows.length === 0) {
      const userResult = await pool.query(
        'SELECT email FROM usuarios WHERE id = $1',
        [req.userId],
      );
      if (userResult.rows.length > 0) {
        const email = userResult.rows[0].email as string;
        result = await pool.query(
          'SELECT * FROM profissionais WHERE email = $1 ORDER BY id LIMIT 1',
          [email],
        );
        if (result.rows.length > 0) {
          await pool.query(
            'UPDATE profissionais SET id_usuario = $1 WHERE id = $2',
            [req.userId, result.rows[0].id],
          );
        }
      }
    }

    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Perfil de profissional não encontrado.' });
      return;
    }
    res.json(result.rows[0]);
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
  const { nome, telefone, email, especialidade, disponibilidade } = req.body as {
    nome: string;
    telefone?: string;
    email?: string;
    especialidade?: string;
    disponibilidade?: string;
  };

  if (!nome) {
    res.status(400).json({ error: 'nome é obrigatório.' });
    return;
  }

  try {
    const result = await pool.query(
      `INSERT INTO profissionais (nome, telefone, email, especialidade, disponibilidade)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [nome, telefone || null, email || null, especialidade || null, disponibilidade || null],
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

// PUT /api/profissionais/:id
router.put('/:id', async (req: AuthRequest, res: Response) => {
  const { nome, telefone, email, especialidade, disponibilidade, status } = req.body as {
    nome?: string;
    telefone?: string;
    email?: string;
    especialidade?: string;
    disponibilidade?: string;
    status?: string;
  };

  try {
    const result = await pool.query(
      `UPDATE profissionais
       SET nome            = COALESCE($1, nome),
           telefone        = COALESCE($2, telefone),
           email           = COALESCE($3, email),
           especialidade   = COALESCE($4, especialidade),
           disponibilidade = COALESCE($5, disponibilidade),
           status          = COALESCE($6, status)
       WHERE id = $7
       RETURNING *`,
      [nome, telefone, email, especialidade, disponibilidade, status, req.params.id],
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

// ─── Horários de trabalho ──────────────────────────────────────────────────

// GET /api/profissionais/:id/horarios
router.get('/:id/horarios', async (req: AuthRequest, res: Response) => {
  try {
    const result = await pool.query(
      `SELECT * FROM horarios_profissional
       WHERE id_profissional = $1
       ORDER BY dia_semana ASC`,
      [req.params.id],
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

// POST /api/profissionais/:id/horarios  — upsert por dia da semana
router.post('/:id/horarios', async (req: AuthRequest, res: Response) => {
  const { dia_semana, hora_inicio, hora_fim, intervalo_min } = req.body as {
    dia_semana: number;
    hora_inicio: string;
    hora_fim: string;
    intervalo_min?: number;
  };

  if (dia_semana === undefined || !hora_inicio || !hora_fim) {
    res.status(400).json({
      error: 'dia_semana, hora_inicio e hora_fim são obrigatórios.',
    });
    return;
  }

  try {
    const result = await pool.query(
      `INSERT INTO horarios_profissional
         (id_profissional, dia_semana, hora_inicio, hora_fim, intervalo_min)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (id_profissional, dia_semana) DO UPDATE
         SET hora_inicio   = EXCLUDED.hora_inicio,
             hora_fim      = EXCLUDED.hora_fim,
             intervalo_min = EXCLUDED.intervalo_min,
             ativo         = TRUE
       RETURNING *`,
      [req.params.id, dia_semana, hora_inicio, hora_fim, intervalo_min ?? 60],
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

// DELETE /api/profissionais/:id/horarios/:dia
router.delete('/:id/horarios/:dia', async (req: AuthRequest, res: Response) => {
  try {
    await pool.query(
      `DELETE FROM horarios_profissional
       WHERE id_profissional = $1 AND dia_semana = $2`,
      [req.params.id, req.params.dia],
    );
    res.status(204).send();
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

// GET /api/profissionais/:id/slots?data=YYYY-MM-DD[&id_servico=<id>][&except_id=<agendamento_id>]
router.get('/:id/slots', async (req: AuthRequest, res: Response) => {
  const { data, except_id, id_servico } = req.query as {
    data?: string;
    except_id?: string;
    id_servico?: string;
  };

  if (!data) {
    res.status(400).json({ error: 'Parâmetro "data" é obrigatório.' });
    return;
  }

  try {
    // Obtem o dia da semana da data informada (0=dom, 6=sab)
    const dowResult = await pool.query(
      `SELECT EXTRACT(DOW FROM $1::date)::int AS dow`,
      [data],
    );
    const dow = dowResult.rows[0].dow as number;

    // Verifica se o profissional trabalha nesse dia
    const schedResult = await pool.query(
      `SELECT hora_inicio, hora_fim, intervalo_min
       FROM horarios_profissional
       WHERE id_profissional = $1 AND dia_semana = $2 AND ativo = TRUE`,
      [req.params.id, dow],
    );

    if (schedResult.rows.length === 0) {
      res.json({ slots: [], message: 'Profissional não atende nesse dia.' });
      return;
    }

    const { hora_inicio, hora_fim, intervalo_min } = schedResult.rows[0] as {
      hora_inicio: string;
      hora_fim: string;
      intervalo_min: number;
    };

    // Duração do serviço solicitado (fallback = intervalo do profissional)
    let servicoDuracao = intervalo_min;
    if (id_servico) {
      const svcRes = await pool.query(
        `SELECT COALESCE(duracao_min, $2) AS duracao_min FROM servicos WHERE id = $1`,
        [id_servico, intervalo_min],
      );
      if (svcRes.rows.length > 0) {
        servicoDuracao = svcRes.rows[0].duracao_min as number;
      }
    }

    const toMinutes = (t: string) => {
      const [h, m] = t.split(':').map(Number);
      return h * 60 + m;
    };
    const toTime = (mins: number) => {
      const h = Math.floor(mins / 60);
      const m = mins % 60;
      return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
    };

    const startMin = toMinutes(hora_inicio);
    const endMin = toMinutes(hora_fim);

    // Gera os slots de horário (baseado no intervalo do profissional)
    const slots: string[] = [];
    let cur = startMin;
    while (cur + servicoDuracao <= endMin) {
      slots.push(toTime(cur));
      cur += intervalo_min;
    }

    // Busca agendamentos existentes com suas durações (para cálculo de sobreposição)
    const bookedValues: unknown[] = [req.params.id, data];
    let bookedQuery = `
      SELECT
        SUBSTRING(a.horario::text, 1, 5) AS horario,
        COALESCE(s.duracao_min, 60) AS duracao_min
      FROM agendamentos a
      JOIN servicos s ON s.id = a.id_servico
      WHERE a.id_profissional = $1
        AND a.data_atendimento = $2
        AND a.status NOT IN ('cancelado')`;

    if (except_id) {
      bookedValues.push(except_id);
      bookedQuery += ` AND a.id <> $${bookedValues.length}`;
    }

    const bookedResult = await pool.query(bookedQuery, bookedValues);

    // Monta lista de intervalos ocupados: [start_min, end_min)
    const occupiedIntervals = bookedResult.rows.map((r: { horario: string; duracao_min: number }) => ({
      start: toMinutes(r.horario),
      end: toMinutes(r.horario) + r.duracao_min,
    }));

    // Um slot está disponível se o intervalo [slot, slot+servicoDuracao) NÃO se sobrepõe
    // a nenhum intervalo ocupado
    const available = slots.map((s) => {
      const slotStart = toMinutes(s);
      const slotEnd = slotStart + servicoDuracao;
      const bloqueado = occupiedIntervals.some(
        (occ) => slotStart < occ.end && slotEnd > occ.start,
      );
      return { horario: s, disponivel: !bloqueado };
    });

    res.json({ slots: available });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno.' });
  }
});

export default router;

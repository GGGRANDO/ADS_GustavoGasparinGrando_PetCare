import nodemailer from 'nodemailer';
import 'dotenv/config';

export async function createTransporter(): Promise<{ transport: nodemailer.Transporter; isTest: boolean }> {
  const smtpConfigured =
    process.env.SMTP_HOST &&
    process.env.SMTP_USER &&
    process.env.SMTP_PASS;

  if (!smtpConfigured) {
    // Sem credenciais reais: usa Ethereal (caixa de entrada de teste)
    const testAccount = await nodemailer.createTestAccount();
    const transport = nodemailer.createTransport({
      host: 'smtp.ethereal.email',
      port: 587,
      secure: false,
      auth: { user: testAccount.user, pass: testAccount.pass },
    });
    return { transport, isTest: true };
  }

  const transport = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT) || 587,
    secure: false,
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
  });
  return { transport, isTest: false };
}

/** Normalises a pg DATE value (may arrive as Date or 'YYYY-MM-DD' string) to 'YYYY-MM-DD'. */
function toDateStr(val: string | Date): string {
  if (val instanceof Date) {
    const y = val.getUTCFullYear();
    const m = String(val.getUTCMonth() + 1).padStart(2, '0');
    const d = String(val.getUTCDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
  }
  return String(val).substring(0, 10); // already 'YYYY-MM-DD'
}

export interface AgendamentoNotificacao {
  profissionalEmail: string;
  profissionalNome: string;
  clienteNome: string;
  servicoDescricao: string;
  dataAtendimento: string | Date;
  horario: string;
  observacao?: string;
}

export async function enviarNotificacaoAgendamento(dados: AgendamentoNotificacao): Promise<void> {
  const dataFormatada = new Date(toDateStr(dados.dataAtendimento) + 'T00:00:00').toLocaleDateString('pt-BR');
  const horarioFormatado = dados.horario.substring(0, 5); // HH:MM

  const { transport, isTest } = await createTransporter();
  const info = await transport.sendMail({
    from: process.env.SMTP_FROM || `PetCare <${process.env.SMTP_USER}>`,
    to: dados.profissionalEmail,
    subject: `[PetCare] Novo agendamento – ${dataFormatada} às ${horarioFormatado}`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #4a90e2;">PetCare – Novo Agendamento</h2>
        <p>Olá, <strong>${dados.profissionalNome}</strong>!</p>
        <p>Você recebeu um novo agendamento com os seguintes detalhes:</p>
        <table style="width:100%; border-collapse: collapse; margin: 16px 0;">
          <tr>
            <td style="padding: 8px; background:#f5f5f5; font-weight:bold; width:40%;">Cliente</td>
            <td style="padding: 8px;">${dados.clienteNome}</td>
          </tr>
          <tr>
            <td style="padding: 8px; background:#f5f5f5; font-weight:bold;">Serviço</td>
            <td style="padding: 8px;">${dados.servicoDescricao}</td>
          </tr>
          <tr>
            <td style="padding: 8px; background:#f5f5f5; font-weight:bold;">Data</td>
            <td style="padding: 8px;">${dataFormatada}</td>
          </tr>
          <tr>
            <td style="padding: 8px; background:#f5f5f5; font-weight:bold;">Horário</td>
            <td style="padding: 8px;">${horarioFormatado}</td>
          </tr>
          ${dados.observacao ? `
          <tr>
            <td style="padding: 8px; background:#f5f5f5; font-weight:bold;">Observação</td>
            <td style="padding: 8px;">${dados.observacao}</td>
          </tr>` : ''}
        </table>
        <p style="color: #666; font-size: 13px;">Acesse o sistema PetCare para gerenciar seus agendamentos.</p>
      </div>
    `,
  });

  if (isTest) {
    console.log(`[DEV] Preview do e-mail (agendamento): ${nodemailer.getTestMessageUrl(info)}`);
  }
}

// ─── Email: confirmação para o cliente ───────────────────────────────────────

export interface ConfirmacaoNotificacao {
  clienteEmail: string;
  clienteNome: string;
  profissionalNome: string;
  servicoDescricao: string;
  dataAtendimento: string | Date;
  horario: string;
}

export async function enviarConfirmacaoParaCliente(dados: ConfirmacaoNotificacao): Promise<void> {
  const dataFormatada = new Date(toDateStr(dados.dataAtendimento) + 'T00:00:00').toLocaleDateString('pt-BR');
  const horarioFormatado = dados.horario.substring(0, 5);

  const { transport, isTest } = await createTransporter();
  const info = await transport.sendMail({
    from: process.env.SMTP_FROM || `PetCare <${process.env.SMTP_USER}>`,
    to: dados.clienteEmail,
    subject: `[PetCare] Agendamento confirmado – ${dataFormatada} às ${horarioFormatado}`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #2e7d32;">PetCare – Agendamento Confirmado ✓</h2>
        <p>Olá, <strong>${dados.clienteNome}</strong>!</p>
        <p>Seu agendamento foi <strong style="color: #2e7d32;">confirmado</strong> pelo profissional.</p>
        <table style="width:100%; border-collapse: collapse; margin: 16px 0;">
          <tr>
            <td style="padding: 8px; background:#f5f5f5; font-weight:bold; width:40%;">Profissional</td>
            <td style="padding: 8px;">${dados.profissionalNome}</td>
          </tr>
          <tr>
            <td style="padding: 8px; background:#f5f5f5; font-weight:bold;">Serviço</td>
            <td style="padding: 8px;">${dados.servicoDescricao}</td>
          </tr>
          <tr>
            <td style="padding: 8px; background:#f5f5f5; font-weight:bold;">Data</td>
            <td style="padding: 8px;">${dataFormatada}</td>
          </tr>
          <tr>
            <td style="padding: 8px; background:#f5f5f5; font-weight:bold;">Horário</td>
            <td style="padding: 8px;">${horarioFormatado}</td>
          </tr>
        </table>
        <p style="color: #666; font-size: 13px;">Acesse o sistema PetCare para mais detalhes e para efetuar o pagamento.</p>
      </div>
    `,
  });

  if (isTest) {
    console.log(`[DEV] Preview do e-mail (confirmação): ${nodemailer.getTestMessageUrl(info)}`);
  }
}

// ─── Email: cancelamento para o cliente ──────────────────────────────────────

export interface CancelamentoNotificacao {
  clienteEmail: string;
  clienteNome: string;
  profissionalNome: string;
  servicoDescricao: string;
  dataAtendimento: string | Date;
  horario: string;
  motivo?: string;
}

export async function enviarCancelamentoParaCliente(dados: CancelamentoNotificacao): Promise<void> {
  const dataFormatada = new Date(toDateStr(dados.dataAtendimento) + 'T00:00:00').toLocaleDateString('pt-BR');
  const horarioFormatado = dados.horario.substring(0, 5);

  const { transport, isTest } = await createTransporter();
  const info = await transport.sendMail({
    from: process.env.SMTP_FROM || `PetCare <${process.env.SMTP_USER}>`,
    to: dados.clienteEmail,
    subject: `[PetCare] Agendamento cancelado – ${dataFormatada} às ${horarioFormatado}`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #c62828;">PetCare – Agendamento Cancelado</h2>
        <p>Olá, <strong>${dados.clienteNome}</strong>.</p>
        <p>Seu agendamento foi <strong style="color: #c62828;">cancelado</strong>.</p>
        <table style="width:100%; border-collapse: collapse; margin: 16px 0;">
          <tr>
            <td style="padding: 8px; background:#f5f5f5; font-weight:bold; width:40%;">Profissional</td>
            <td style="padding: 8px;">${dados.profissionalNome}</td>
          </tr>
          <tr>
            <td style="padding: 8px; background:#f5f5f5; font-weight:bold;">Serviço</td>
            <td style="padding: 8px;">${dados.servicoDescricao}</td>
          </tr>
          <tr>
            <td style="padding: 8px; background:#f5f5f5; font-weight:bold;">Data</td>
            <td style="padding: 8px;">${dataFormatada}</td>
          </tr>
          <tr>
            <td style="padding: 8px; background:#f5f5f5; font-weight:bold;">Horário</td>
            <td style="padding: 8px;">${horarioFormatado}</td>
          </tr>
          ${dados.motivo ? `<tr>
            <td style="padding: 8px; background:#f5f5f5; font-weight:bold;">Motivo</td>
            <td style="padding: 8px;">${dados.motivo}</td>
          </tr>` : ''}
        </table>
        <p style="color: #666; font-size: 13px;">Entre em contato para mais informações ou para fazer um novo agendamento.</p>
      </div>
    `,
  });

  if (isTest) {
    console.log(`[DEV] Preview do e-mail (cancelamento): ${nodemailer.getTestMessageUrl(info)}`);
  }
}

// ─── Email: cancelamento para o prestador ────────────────────────────────────

export interface CancelamentoPrestadorNotificacao {
  profissionalEmail: string;
  profissionalNome: string;
  clienteNome: string;
  servicoDescricao: string;
  dataAtendimento: string | Date;
  horario: string;
  motivo?: string;
}

export async function enviarCancelamentoParaPrestador(dados: CancelamentoPrestadorNotificacao): Promise<void> {
  const dataFormatada = new Date(toDateStr(dados.dataAtendimento) + 'T00:00:00').toLocaleDateString('pt-BR');
  const horarioFormatado = dados.horario.substring(0, 5);

  const { transport, isTest } = await createTransporter();
  const info = await transport.sendMail({
    from: process.env.SMTP_FROM || `PetCare <${process.env.SMTP_USER}>`,
    to: dados.profissionalEmail,
    subject: `[PetCare] Agendamento cancelado – ${dataFormatada} às ${horarioFormatado}`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #c62828;">PetCare – Agendamento Cancelado</h2>
        <p>Olá, <strong>${dados.profissionalNome}</strong>.</p>
        <p>Um agendamento foi <strong style="color: #c62828;">cancelado</strong>.</p>
        <table style="width:100%; border-collapse: collapse; margin: 16px 0;">
          <tr>
            <td style="padding: 8px; background:#f5f5f5; font-weight:bold; width:40%;">Cliente</td>
            <td style="padding: 8px;">${dados.clienteNome}</td>
          </tr>
          <tr>
            <td style="padding: 8px; background:#f5f5f5; font-weight:bold;">Serviço</td>
            <td style="padding: 8px;">${dados.servicoDescricao}</td>
          </tr>
          <tr>
            <td style="padding: 8px; background:#f5f5f5; font-weight:bold;">Data</td>
            <td style="padding: 8px;">${dataFormatada}</td>
          </tr>
          <tr>
            <td style="padding: 8px; background:#f5f5f5; font-weight:bold;">Horário</td>
            <td style="padding: 8px;">${horarioFormatado}</td>
          </tr>
          ${dados.motivo ? `<tr>
            <td style="padding: 8px; background:#f5f5f5; font-weight:bold;">Motivo</td>
            <td style="padding: 8px;">${dados.motivo}</td>
          </tr>` : ''}
        </table>
        <p style="color: #666; font-size: 13px;">Acesse o sistema PetCare para gerenciar sua agenda.</p>
      </div>
    `,
  });

  if (isTest) {
    console.log(`[DEV] Preview do e-mail (cancelamento prestador): ${nodemailer.getTestMessageUrl(info)}`);
  }
}

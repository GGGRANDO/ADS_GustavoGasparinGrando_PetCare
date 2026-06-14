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

export interface AgendamentoNotificacao {
  profissionalEmail: string;
  profissionalNome: string;
  clienteNome: string;
  servicoDescricao: string;
  dataAtendimento: string;
  horario: string;
  observacao?: string;
}

export async function enviarNotificacaoAgendamento(dados: AgendamentoNotificacao): Promise<void> {
  const dataFormatada = new Date(dados.dataAtendimento + 'T00:00:00').toLocaleDateString('pt-BR');
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

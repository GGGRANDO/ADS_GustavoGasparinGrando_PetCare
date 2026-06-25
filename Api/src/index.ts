import 'dotenv/config';
import express from 'express';
import cors from 'cors';

import authRouter         from './routes/auth';
import clientsRouter      from './routes/clients';
import professionalsRouter from './routes/professionals';
import servicesRouter     from './routes/services';
import appointmentsRouter from './routes/appointments';
import paymentsRouter     from './routes/payments';
import categoriasRouter   from './routes/categories';

const app = express();
app.use(cors());
app.use(express.json());

app.get('/health', (_req, res) => res.json({ status: 'ok' }));

app.use('/api/auth',          authRouter);
app.use('/api/clientes',      clientsRouter);
app.use('/api/profissionais', professionalsRouter);
app.use('/api/servicos',      servicesRouter);
app.use('/api/agendamentos',  appointmentsRouter);
app.use('/api/pagamentos',    paymentsRouter);
app.use('/api/categorias',    categoriasRouter);

const port = process.env.PORT ? Number(process.env.PORT) : 3000;
app.listen(port, () => console.log(`PetCare API listening on port ${port}`));


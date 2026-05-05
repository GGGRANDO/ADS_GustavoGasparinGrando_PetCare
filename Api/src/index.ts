import express from 'express';
import cors from 'cors';

const app = express();
app.use(cors());
app.use(express.json());

app.get('/health', (_req, res) => res.json({ status: 'ok' }));

app.get('/api/clients', (_req, res) => {
  res.json([
    { id: 1, name: 'Fulano de Tal', email: 'fulano@example.com' }
  ]);
});

const port = process.env.PORT ? Number(process.env.PORT) : 3000;
app.listen(port, () => console.log(`Server listening on port ${port}`));

import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

export interface AuthRequest extends Request {
  userId?: number;
  userPerfil?: string;
}

export function authMiddleware(req: AuthRequest, res: Response, next: NextFunction) {
  const header = req.headers['authorization'];
  if (!header) {
    res.status(401).json({ error: 'Token não fornecido.' });
    return;
  }

  const token = header.startsWith('Bearer ') ? header.slice(7) : header;
  const secret = process.env.JWT_SECRET || 'petcare_secret_change_in_production';

  try {
    const payload = jwt.verify(token, secret) as { id: number; perfil: string };
    req.userId = payload.id;
    req.userPerfil = payload.perfil;
    next();
  } catch {
    res.status(401).json({ error: 'Token inválido ou expirado.' });
  }
}

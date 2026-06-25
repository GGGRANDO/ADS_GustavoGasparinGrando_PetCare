# PetCare – Apresentação Técnica do Código
**Universidade de Passo Fundo – UPF | Gustavo Gasparin Grando | 2026**

---

## SLIDE 1 — Visão Geral da Arquitetura

```
┌──────────────────────────────────────────────────────────┐
│                     FLUTTER APP                          │
│  Web / Android / iOS   (Material Design 3, Dart 3)       │
│  Gerenciamento de estado: Provider (AuthProvider)        │
└────────────────────┬─────────────────────────────────────┘
                     │ HTTP (JWT Bearer)
                     ▼
┌──────────────────────────────────────────────────────────┐
│                  NODE.JS + EXPRESS API                   │
│  TypeScript 5 · Rotas REST · Middleware JWT              │
│  Nodemailer (e-mails transacionais)                      │
└────────────────────┬─────────────────────────────────────┘
                     │ node-postgres (pool)
                     ▼
┌──────────────────────────────────────────────────────────┐
│               POSTGRESQL 15                              │
│  Banco relacional com integridade referencial            │
└──────────────────────────────────────────────────────────┘
```

**Stack resumida**
| Camada | Tecnologia |
|--------|-----------|
| Frontend | Flutter 3 / Dart 3 |
| Backend | Node.js 18 + Express 4 + TypeScript 5 |
| Banco | PostgreSQL 15 |
| Auth | JWT + bcryptjs |
| Email | Nodemailer (Ethereal dev / SMTP prod) |

---

## SLIDE 2 — Estrutura do Banco de Dados

```sql
usuarios          -- login, perfil (admin/profissional/cliente)
clientes          -- tutores vinculados a usuários
profissionais     -- prestadores vinculados a usuários
categorias_servico-- categorias de serviço criadas pelo admin
servicos          -- vinculados a profissional + categoria
horarios_profissional -- grade de disponibilidade por dia da semana
agendamentos      -- booking com status machine completo
pagamentos        -- controle financeiro por agendamento
password_reset_tokens -- tokens de recuperação de senha
```

**Destaques de integridade:**
- Exclusão de cliente/profissional bloqueada via `HTTP 409` se existirem agendamentos vinculados
- Cascata configurada em `horarios_profissional ON DELETE CASCADE`
- Campo `motivo_cancelamento` adicionado via `ALTER TABLE` sem quebrar dados existentes

---

## SLIDE 3 — Autenticação e Controle de Acesso (RF01)

**Fluxo de Login:**
```
App → POST /api/auth/login  →  valida bcrypt  →  retorna JWT
App armazena token em shared_preferences
Todas as requisições enviam: Authorization: Bearer <token>
authMiddleware valida e injeta req.user em cada rota
```

**Redirecionamento por perfil:**
```dart
// _AuthGate (main.dart)
if (auth.perfil == 'profissional') → PrestadorDashboardScreen
if (auth.perfil == 'cliente')      → ClienteDashboardScreen
default (admin/atendente)          → HomeScreen
```

**Recuperação de senha:**
- Token de 6 dígitos gerado aleatoriamente
- Validade de 30 minutos, marcado `usado=true` após uso
- Senha rehashed com bcrypt antes de salvar

---

## SLIDE 4 — Máquina de Status dos Agendamentos (RF05)

```
                  NOVO AGENDAMENTO
                        │
                        ▼
              aguardando_confirmacao
                /               \
               ✓                ✗ (recusa com motivo)
              /                   \
         confirmado             cancelado ◄──── cancelamento manual
              │
    ┌─────────┴──────────┐
    │                    │
 concluido          cancelado
```

**Regras implementadas:**
- Backend sempre cria com `aguardando_confirmacao` (hardcoded no INSERT)
- `PATCH /:id/confirmar` → status='confirmado' + e-mail para cliente
- `PATCH /:id/cancelar` → status='cancelado' + motivo + e-mail para cliente
- Pagamento só liberado quando status='confirmado'

---

## SLIDE 5 — Controle Inteligente de Slots (RF05 + RF06)

**Como funciona:**
1. Profissional cadastra grade semanal: `(dia, hora_inicio, hora_fim, intervalo_min)`
2. `/api/profissionais/:id/slots?data=YYYY-MM-DD&id_servico=X` gera os slots do dia
3. Cada slot é marcado `disponivel: false` se houver sobreposição com agendamento existente

**Algoritmo de conflito (overlap interval):**
```sql
-- Novo agendamento [novo_inicio, novo_inicio + nova_duracao) conflita com
-- existente [h_existente, h_existente + duracao_existente) se:
novo_inicio < (h_existente + duracao_existente * '1 min')
AND h_existente < (novo_inicio + nova_duracao * '1 min')
```

**Flutter:**
- `agendamento_form_screen.dart` recarrega slots ao mudar profissional, data ou serviço
- Chips desabilitados para horários ocupados

---

## SLIDE 6 — Identidade Visual e Tema (RNF01)

**Paleta de cores PetCare:**
```dart
Color(0xFF4A90A4)  // Azul-petróleo  → primary, AppBar
Color(0xFFF5A623)  // Âmbar          → secondary, destaques
Color(0xFF5BA08A)  // Verde-teal      → ação profissional
Color(0xFF7B6FAB)  // Lavanda         → categorias, horários
```

**ThemeData centralizado em `main.dart`:**
- AppBarTheme, ElevatedButtonTheme, FilledButtonTheme, FABTheme, InputDecorationTheme
- Todos os widgets herdam do tema → zero override hardcoded nas telas corrigidas

---

## SLIDE 7 — Painéis por Perfil (RF07)

| Módulo | Admin | Prestador | Cliente |
|--------|-------|-----------|---------|
| Clientes | ✅ CRUD | ✗ | ✗ |
| Profissionais | ✅ CRUD | ✗ | 📖 Catálogo |
| Categorias de Serviço | ✅ CRUD | ✗ | ✗ |
| Serviços | ✅ CRUD global | ✅ Apenas os seus | 📖 Catálogo |
| Agendamentos | ✅ Todos | ✅ Somente seus | ✅ Somente seus |
| Horários de Atendimento | ✅ via prof. form | ✅ Card direto | ✗ |
| Pagamentos | ✅ | ✗ | ✅ Pagar |
| Meu Perfil | ✗ | ✅ | ✅ |

---

## SLIDE 8 — E-mails Transacionais

| Evento | Destinatário | Assunto |
|--------|-------------|---------|
| Novo agendamento criado | Prestador | `[PetCare] Novo agendamento – DD/MM/YYYY às HH:MM` |
| Agendamento confirmado | Cliente | `[PetCare] Agendamento confirmado – DD/MM/YYYY às HH:MM` |
| Agendamento cancelado | Cliente | `[PetCare] Agendamento cancelado – DD/MM/YYYY às HH:MM` |

**Correção aplicada:**
- `data_atendimento` vindo do PostgreSQL como objeto `Date` JS → `toDateStr()` normaliza para `YYYY-MM-DD` antes de formatar com `toLocaleDateString('pt-BR')`
- Sem essa correção o subject ficava `"Invalid Date às HH:MM"`

---

## SLIDE 9 — Inconsistências Corrigidas Durante a Revisão DVP

| # | Problema | Impacto | Correção |
|---|---------|---------|---------|
| 1 | AppBars com `Colors.orange`/`Colors.teal` hardcoded | Visual fora do tema | Removidos; herdam ThemeData |
| 2 | Status padrão `'agendado'` no form | Inconsistente com backend (`aguardando_confirmacao`) | Alterado para `'aguardando_confirmacao'` |
| 3 | `'agendado'` listado no dropdown de status | Status obsoleto no sistema | Substituído por `'aguardando_confirmacao'` |
| 4 | Painel Prestador sem card "Horários de Atendimento" | DVP RF07 exige o módulo | Card adicionado → `HorariosProfissionalScreen` |
| 5 | `data_atendimento` como objeto `Date` JS no e-mail | Subject com "Invalid Date" | `toDateStr()` adicionado em `mailer.ts` |
| 6 | `Colors.orange` em `EditMeuPerfilPrestadorScreen` | Fora do tema da marca | Trocado para `Color(0xFF4A90A4)` |

---

## SLIDE 10 — Fluxo de Testes Funcionais

### TC01 – Login e redirecionamento por perfil
1. Abrir app → tela de Login
2. Informar e-mail/senha de **admin** → deve ir para `HomeScreen` (5 cards: Clientes, Profissionais, Serviços, Agendamentos, Categorias)
3. Logout → informar e-mail/senha de **profissional** → deve ir para `PrestadorDashboardScreen` (4 cards: Minha Agenda, Meus Serviços, Horários de Atendimento, Meu Perfil)
4. Logout → informar e-mail/senha de **cliente** → deve ir para `ClienteDashboardScreen`
5. Credenciais erradas → mensagem de erro sem indicar qual campo falhou ✅

### TC02 – Recuperação de senha
1. Tela Login → "Esqueci minha senha" → informar e-mail válido
2. Token de 6 dígitos enviado ao e-mail (dev: link Ethereal no console)
3. Informar token + nova senha → senha atualizada ✅
4. Token expirado/usado → mensagem de erro ✅

### TC03 – Gerenciar Categorias (admin)
1. Admin → "Categorias" → lista vazia com FAB
2. Tap FAB → formulário → preencher Nome obrigatório → salvar
3. Categoria aparece na lista com chip "ativo"
4. Editar → alterar nome → salvar → lista atualizada
5. Excluir categoria sem serviços → excluída com sucesso
6. Criar serviço vinculado à categoria → tentar excluir categoria → deve retornar erro 409 ✅

### TC04 – Criar Serviço (prestador)
1. Prestador → "Meus Serviços" → FAB
2. Dropdown "Categoria" carrega as categorias ativas do admin
3. Preencher nome, valor, duração em minutos (campo livre)
4. Salvar → serviço aparece na lista com chip de categoria ✅

### TC05 – Horários de Atendimento (prestador)
1. Prestador → "Horários de Atendimento"
2. Selecionar dia da semana → definir hora início, hora fim, intervalo
3. Salvar → upsert (não duplica se o dia já existia)
4. Remover dia → slot não aparece mais no agendamento ✅

### TC06 – Agendar (cliente)
1. Cliente → "Novo Agendamento"
2. Campo "Cliente" oculto (preenchido automaticamente) ✅
3. Campo "Status" oculto (modo cliente) ✅
4. Selecionar profissional → dropdown de serviços filtra apenas os do profissional ✅
5. Selecionar serviço → selecionar data → grade de slots carrega com horários disponíveis
6. Horários ocupados aparecem desabilitados (chip cinza)
7. Selecionar slot disponível → "Agendar" → confirmação → opção de pagar agora ✅

### TC07 – Conflito de horário (API)
1. Com dois clientes diferentes: agendar o mesmo profissional, mesma data, mesmo slot
2. Segundo agendamento deve retornar `HTTP 409` com mensagem de conflito ✅

### TC08 – Confirmação pelo prestador
1. Prestador → "Minha Agenda" → banner laranja com contador de pendentes
2. Tap ✓ em agendamento "aguardando_confirmacao" → status vira "confirmado"
3. E-mail de confirmação enviado ao cliente (dev: log no console com link Ethereal) ✅

### TC09 – Pagamento
1. Admin/cliente → agendamento com status ≠ 'confirmado' → tela de pagamento exibe card bloqueador laranja
2. Agendamento confirmado → selecionar forma (PIX / Cartão / Boleto / Dinheiro / Transferência) → registrar ✅

### TC10 – Cancelamento com motivo
1. Prestador ou admin → agendamento → "Recusar" ou "Cancelar"
2. Dialog solicita motivo (opcional)
3. Status vira 'cancelado' + `motivo_cancelamento` gravado
4. E-mail de cancelamento enviado ao cliente com o motivo ✅

---

## CONFORMIDADE COM O DVP

| Requisito | Status | Observações |
|-----------|--------|-------------|
| RF01 – Login + JWT + perfil | ✅ Implementado | Redirecionamento correto por perfil |
| RF01 – Recuperação de senha | ✅ Implementado | Token 6 dígitos, validade 30 min, bcrypt |
| RF01 – Cadastro de usuário | ✅ Implementado | Registro com perfil cliente/profissional |
| RF02 – Gerenciar Clientes | ✅ Implementado | CRUD + bloqueio exclusão (409) |
| RF03 – Gerenciar Profissionais | ✅ Implementado | CRUD + catálogo para cliente |
| RF04 – Gerenciar Serviços | ✅ Implementado | Com categoria + duração livre |
| RF04 – Catálogo de serviços | ✅ Implementado | Cards com valor, duração, profissional |
| RF05 – Agendamentos + slots | ✅ Implementado | Overlap check + status machine |
| RF05 – Modo cliente oculta campos | ✅ Implementado | Cliente e Status ocultos |
| RF06 – Horários de atendimento | ✅ Implementado | Upsert por dia da semana |
| RF07 – Painel Prestador (4 módulos) | ✅ Implementado | Horários agora direto no dashboard |
| RF07 – Painel Cliente (catálogos + agenda) | ✅ Implementado | Badges de agendamentos do dia |
| RNF01 – Interface responsiva | ✅ Material 3 | Web + Android + iOS via Flutter |
| RNF02 – Autenticação segura + segregação | ✅ JWT + bcrypt | authMiddleware em todas as rotas |
| RNF03 – Integridade relacional | ✅ PostgreSQL FK | Bloqueios de deleção implementados |
| RNF04 – Tempo de resposta adequado | ✅ Pool de conexões | node-postgres com pool |
| RNF05 – Organização em camadas | ✅ 3 camadas | Flutter / Express / PostgreSQL |
| **Extra** – Categorias de serviço | ✅ Implementado | Admin cria, prestador seleciona |
| **Extra** – E-mails transacionais | ✅ Implementado | 3 eventos com Nodemailer |
| **Extra** – Módulo de pagamentos | ✅ Implementado | PIX, cartão, boleto, dinheiro, transferência |

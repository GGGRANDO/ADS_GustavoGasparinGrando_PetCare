# Universidade de Passo Fundo – UPF
# DOCUMENTO DE VISÃO DO PRODUTO – DVP
## Projeto de Aplicativo PetCare
### Gustavo Gasparin Grando
### 2026

---

## Histórico de Alterações do Documento

| Versão | Alteração efetuada | Responsável | Data |
|--------|-------------------|-------------|------|
| 1.0 | Documento inicial do projeto | Gustavo | 08/03/2026 |
| 2.0 | Complementação do DVP com visão do produto, requisitos, diagramas, arquitetura e cronograma | Gustavo | 05/04/2026 |
| 3.0 | Atualização do DVP conforme implementação real: API REST, PostgreSQL, autenticação JWT, módulo do prestador, módulo do cliente, horários de atendimento e agendamento por slots | Gustavo | 06/06/2026 |

---

## Sumário

1. REQUISITOS
   - 1.1 Fundamentação dos Requisitos
     - 1.1.1 Técnicas Utilizadas para Requisitos
   - 1.2 Concepção dos Requisitos
     - 1.2.1 Identificação do Domínio
     - 1.2.2 Principais Stakeholders
   - 1.3 Elicitação dos Requisitos
     - 1.3.1 Requisitos Funcionais (RF)
     - 1.3.2 Requisitos Não Funcionais (RNF)
   - 1.4 Especificação dos Requisitos
     - 1.4.1 UML – Diagrama de Casos de Uso
     - 1.4.2 Histórias de Usuário por Caso de Uso
   - 1.5 Projeto Técnico
     - 1.5.1 Arquitetura Utilizada
     - 1.5.2 Ferramentas e Tecnologias
     - 1.5.3 Modelo Lógico do Banco de Dados
2. GESTÃO DE PROJETOS
   - 2.1 Cronograma de Codificação do Projeto

---

# 1. REQUISITOS

## 1.1 Fundamentação dos Requisitos

### 1.1.1 Técnicas Utilizadas para Requisitos

A definição dos requisitos do PetCare foi baseada nas seguintes técnicas:

- **Análise de domínio**: estudo do contexto de serviços pet para identificar as necessidades reais dos usuários;
- **Entrevistas e observação**: coleta de necessidades dos perfis de administrador, profissional e cliente;
- **EAP (Estrutura Analítica do Projeto)**: organização das entregas previstas nas sprints semanais;
- **Priorização MoSCoW**: classificação dos requisitos entre essenciais, importantes e desejáveis para o MVP;
- **Refinamento iterativo**: evolução dos requisitos durante o desenvolvimento, incorporando novas funcionalidades como horários de atendimento por slots e painéis diferenciados por perfil.

O objetivo foi estruturar um sistema de agendamento e gestão de serviços pet com foco em controle operacional, segurança de acesso e boa experiência de uso.

---

## 1.2 Concepção dos Requisitos

### 1.2.1 Identificação do Domínio

O domínio do sistema está relacionado à intermediação e gestão de serviços de cuidado para animais de estimação. O aplicativo PetCare tem como objetivo conectar tutores de pets a profissionais que oferecem serviços como hospedagem, passeios, banho, tosa, alimentação e acompanhamento dos animais.

A plataforma permite o cadastro de clientes, profissionais, serviços e agendamentos, oferecendo um fluxo centralizado para controle de atendimentos. A proposta do produto é reduzir falhas manuais de agenda, evitar conflitos de horários, manter o histórico de atendimentos e facilitar a consulta das informações necessárias para tomada de decisão.

O sistema evoluiu para uma arquitetura cliente-servidor (Flutter + API REST + PostgreSQL), com autenticação JWT, painéis diferenciados por perfil (administrador, profissional/prestador e cliente/tutor), configuração de horários de trabalho por dia da semana com slots automáticos de disponibilidade, e catálogo de serviços com valor e duração por profissional.

### 1.2.2 Principais Stakeholders

| Stakeholder | Papel no Projeto | Interesse Principal | Contato |
|-------------|-----------------|--------------------|---------| 
| Gustavo Gasparin Grando | Gerente do projeto | Definir escopo, acompanhar desenvolvimento e validar entregas | 177641@upf.br |
| Tutor do pet (Cliente) | Cliente final | Consultar serviços disponíveis com valores e duração, agendar horários com facilidade e segurança | Usuário do sistema |
| Profissional cuidador (Prestador) | Prestador de serviço | Organizar agenda, cadastrar serviços ofertados com preços e durações, configurar horários de atendimento e visualizar agendamentos do dia | Usuário do sistema |
| Administrador / Atendente | Responsável operacional | Controlar acessos, gerenciar cadastros de clientes, profissionais, serviços e agendamentos | Usuário interno |

---

## 1.3 Elicitação dos Requisitos

### 1.3.1 Requisitos Funcionais (RF)

---

#### RF01 – Gerenciar Login

**Importância:** essencial  
**Priorização:** 1  
**Dependência com outro(s) requisito(s):** nenhuma

**Problema / Necessidades Identificadas:**  
Garantir que apenas usuários autorizados acessem o sistema por meio de autenticação segura, com redirecionamento automático para o painel correspondente ao perfil (administrador, profissional ou cliente).

**Fluxos Esperados:**
- Permitir login por e-mail e senha para usuários previamente cadastrados.
- Validar credenciais via API REST com autenticação JWT antes de conceder acesso.
- Redirecionar o usuário para o módulo correspondente ao seu perfil (administrador → painel geral; profissional → Painel do Prestador; cliente → Painel do Cliente).
- Disponibilizar recuperação de senha via e-mail com token de 6 dígitos.
- Suportar registro de novos usuários com perfil de cliente ou profissional.

---

#### RF02 – Gerenciar Clientes

**Importância:** essencial  
**Priorização:** 1  
**Dependência com outro(s) requisito(s):** RF01

**Problema / Necessidades Identificadas:**  
Organizar os dados dos tutores e seus pets para apoiar atendimentos e agendamentos sem perda de informação.

**Fluxos Esperados:**
- Cadastrar clientes com nome, telefone, e-mail e observações.
- Registrar automaticamente a data de cadastro.
- Editar dados cadastrais sempre que necessário.
- Bloquear exclusão quando existirem agendamentos vinculados, permitindo apenas inativação.
- Disponibilizar busca rápida e filtragem dos clientes cadastrados.
- Vincular cliente ao usuário autenticado via `id_usuario`.

---

#### RF03 – Gerenciar Profissionais

**Importância:** essencial  
**Priorização:** 1  
**Dependência com outro(s) requisito(s):** RF01

**Problema / Necessidades Identificadas:**  
Manter os profissionais organizados para compor corretamente os agendamentos e serviços oferecidos.

**Fluxos Esperados:**
- Cadastrar profissionais com área de atuação, contato e disponibilidade.
- Listar profissionais ativos no sistema, com filtro por especialidade.
- Editar dados e atualizar disponibilidade quando necessário.
- Bloquear exclusão quando houver vínculo com agendamentos já registrados.
- Vincular profissional ao usuário autenticado via `id_usuario`.
- Exibir catálogo de profissionais disponíveis para clientes com botão de agendamento direto.

---

#### RF04 – Gerenciar Serviços

**Importância:** essencial  
**Priorização:** 1  
**Dependência com outro(s) requisito(s):** RF01, RF03

**Problema / Necessidades Identificadas:**  
Manter padronizado o cadastro dos serviços disponíveis, vinculados ao profissional responsável, com valor e duração definidos, para evitar erros de atendimento e de cobrança.

**Fluxos Esperados:**
- Cadastrar serviços (passeio, hospedagem, banho, tosa, acompanhamento etc.) com descrição, valor e observações.
- Definir a **duração do serviço** (15, 30, 45, 60, 90, 120 ou 180 minutos) para controle de slots de agenda.
- Vincular cada serviço a um **profissional específico** (`id_profissional`).
- Editar descrição, valor, duração e observações dos serviços cadastrados.
- Bloquear exclusão de serviços vinculados a agendamentos existentes.
- Exibir **catálogo de serviços** para clientes com valor, duração e nome do profissional em cards visuais.
- Permitir filtro e busca por nome do serviço ou profissional no catálogo.

---

#### RF05 – Gerenciar Agendamentos

**Importância:** essencial  
**Priorização:** 1  
**Dependência com outro(s) requisito(s):** RF01, RF02, RF03, RF04, RF06

**Problema / Necessidades Identificadas:**  
Estruturar um controle eficiente de agenda, evitando conflitos de horário e mantendo histórico dos atendimentos.

**Fluxos Esperados:**
- Permitir agendamento informando cliente, profissional, serviço, data, status e observações.
- Selecionar horário por meio de **grade de slots disponíveis** gerada automaticamente com base nos horários de trabalho do profissional.
- Ao selecionar o profissional, exibir apenas os **serviços vinculados a ele** com preços.
- Impedir dois agendamentos no mesmo horário para o mesmo profissional (conflito bloqueado na API).
- Permitir edição, confirmação e cancelamento com manutenção do histórico.
- Exibir agenda filtrável por data, cliente, profissional e status.
- No modo cliente, ocultar dropdown de cliente (preenchido automaticamente) e campo de status.
- Permitir agendamento direto a partir do catálogo de serviços ou do catálogo de profissionais.

---

#### RF06 – Gerenciar Horários de Atendimento do Profissional

**Importância:** essencial  
**Priorização:** 1  
**Dependência com outro(s) requisito(s):** RF01, RF03

**Problema / Necessidades Identificadas:**  
Permitir que o profissional configure os dias e horários em que atende, para que o sistema gere automaticamente os slots disponíveis para agendamento.

**Fluxos Esperados:**
- Cadastrar horário de trabalho por **dia da semana** (domingo a sábado).
- Definir hora de início, hora de fim e **duração de cada slot** (30, 45, 60 ou 90 minutos).
- Operação de upsert: atualizar o horário do dia caso já exista, sem duplicações.
- Remover horários de dias específicos quando o profissional não atender naquele dia.
- Gerar automaticamente a lista de slots ao receber uma data de consulta, excluindo horários já ocupados.

---

#### RF07 – Painel do Prestador de Serviço

**Importância:** essencial  
**Priorização:** 2  
**Dependência com outro(s) requisito(s):** RF01, RF03, RF04, RF05, RF06

**Problema / Necessidades Identificadas:**  
Oferecer ao profissional uma visão centralizada e exclusiva para gerenciar seus serviços, horários e agenda, sem acesso aos módulos administrativos.

**Fluxos Esperados:**
- Exibir painel personalizado após login com perfil `profissional`.
- Mostrar nome, especialidade e **contador de agendamentos do dia** no cabeçalho.
- Disponibilizar módulos: Minha Agenda, Meus Serviços, Horários de Atendimento e Meu Perfil.
- Acesso à gestão de serviços filtrando apenas os serviços do próprio profissional.
- Acesso à configuração de horários de atendimento.

---

#### RF08 – Painel do Cliente / Catálogo

**Importância:** essencial  
**Priorização:** 2  
**Dependência com outro(s) requisito(s):** RF01, RF02, RF04, RF05

**Problema / Necessidades Identificadas:**  
Oferecer ao cliente uma experiência de autoatendimento para consultar serviços disponíveis, ver valores e durações, escolher profissional e agendar diretamente pelo app.

**Fluxos Esperados:**
- Exibir painel personalizado após login com perfil `cliente`.
- Mostrar nome do cliente com badges de agendamentos do dia e pendentes.
- Disponibilizar atalho de **Novo Agendamento** direto no painel.
- Acessar **Catálogo de Serviços** com cards exibindo preço, duração e profissional responsável.
- Acessar **Catálogo de Profissionais** com botão "Agendar" por profissional.
- Acessar histórico de **Meus Agendamentos** filtrado pelo próprio cliente.

---

### 1.3.2 Requisitos Não Funcionais (RNF)

| Identificação | Descrição |
|---------------|-----------|
| RNF01 | A interface deve ser responsiva e de fácil utilização em Android, iOS e web (Chrome). |
| RNF02 | O sistema deve garantir autenticação segura com JWT e segregação de acessos por perfil (admin, profissional, cliente). |
| RNF03 | Os dados devem ser persistidos de forma consistente, com integridade relacional no banco PostgreSQL (chaves estrangeiras, constraints). |
| RNF04 | O tempo de resposta para consultas simples deve ser adequado ao uso operacional cotidiano (< 2 segundos em rede local). |
| RNF05 | A aplicação deve ser organizada em camadas (API → Routes → DB; App → Screens → Services → Models) para facilitar manutenção e evolução. |
| RNF06 | Senhas devem ser armazenadas com hash seguro (bcrypt) e nunca trafegar em texto plano. |
| RNF07 | A API deve validar e sanitizar todos os parâmetros recebidos antes de executar queries no banco. |
| RNF08 | O token de recuperação de senha deve ter validade limitada e ser marcado como usado após a redefinição. |

---

## 1.4 Especificação dos Requisitos

### 1.4.1 UML – Diagrama de Casos de Uso

O diagrama abaixo apresenta os principais casos de uso definidos para a solução, cobrindo autenticação, manutenção de cadastros, configuração de agenda e controle de agendamentos.

```
                         ┌─────────────────────────────────────────────────────┐
                         │                   Sistema PetCare                   │
                         │                                                     │
                         │  [UC01 Gerenciar Login]                             │
  ┌──────────────┐       │  [UC02 Gerenciar Clientes]                         │
  │ Administrador│───────│  [UC03 Gerenciar Profissionais]                     │
  │  / Atendente │       │  [UC04 Gerenciar Serviços]                         │
  └──────────────┘       │  [UC05 Gerenciar Agendamentos]                      │
                         │                                                     │
  ┌──────────────┐       │  [UC06 Configurar Horários de Atendimento]         │
  │ Profissional │───────│  [UC04 Gerenciar Próprios Serviços]                │
  │  (Prestador) │       │  [UC05 Consultar Própria Agenda]                   │
  └──────────────┘       │                                                     │
                         │  [UC07 Consultar Catálogo de Serviços]             │
  ┌──────────────┐       │  [UC08 Consultar Catálogo de Profissionais]        │
  │  Tutor/Pet   │───────│  [UC05 Solicitar Agendamento]                      │
  │  (Cliente)   │       │  [UC05 Consultar Próprios Agendamentos]            │
  └──────────────┘       │  [UC01 Recuperar Senha]                            │
                         └─────────────────────────────────────────────────────┘
```

*Figura 1 – Diagrama de casos de uso do aplicativo PetCare.*

---

### 1.4.2 Histórias de Usuário por Caso de Uso

---

#### UC01 – Gerenciar Login

**Objetivo:** Controlar o acesso ao sistema por meio de autenticação segura, com redirecionamento automático ao painel do perfil correspondente.

---

**História: HU01 – Logar na aplicação**  
**Descrição:** COMO usuário (administrador, profissional ou cliente), QUERO informar meu e-mail e senha, PARA acessar o sistema e ser redirecionado ao painel correspondente ao meu perfil.  
**Regras de Negócio:**  
- Login válido significa que e-mail e senha (comparados com hash bcrypt) foram encontrados no banco.  
- O token JWT gerado deve ser armazenado localmente e enviado no header `Authorization: Bearer` em todas as requisições autenticadas.  
- Profissionais são redirecionados ao Painel do Prestador; clientes ao Painel do Cliente; demais perfis ao painel administrativo geral.  
**Critérios de Aceite:**  
- Acesso liberado com credenciais válidas e redirecionamento correto por perfil.  
- Se e-mail ou senha inválidos, exibir mensagem de erro sem indicar qual campo falhou.

---

**História: HU02 – Recuperar senha**  
**Descrição:** COMO usuário, QUERO solicitar recuperação de senha informando meu e-mail, PARA receber um código de 6 dígitos e redefinir minha senha com segurança.  
**Regras de Negócio:**  
- O token de 6 dígitos tem validade de 30 minutos e é marcado como usado após a redefinição.  
- A nova senha é armazenada com hash bcrypt.  
**Critérios de Aceite:**  
- Ao informar código válido e não expirado, a senha é atualizada com sucesso.  
- Token expirado ou já utilizado deve exibir mensagem de erro.

---

#### UC02 – Gerenciar Clientes

**Objetivo:** Manter organizada a base de tutores cadastrados com possibilidade de busca, edição e inativação.

---

**História: HU03 – Cadastrar cliente**  
**Descrição:** COMO atendente, QUERO cadastrar um novo cliente com nome, telefone, e-mail e observações, PARA manter a base de tutores organizada.  
**Regras de Negócio:**  
- Nome é obrigatório. Data de cadastro é gerada automaticamente.  
- Um cliente não pode ser excluído se houver agendamentos vinculados; nesse caso, apenas inativação é permitida.  
**Critérios de Aceite:**  
- Cliente salvo e exibido na listagem após cadastro.  
- Tentativa de exclusão com agendamentos vinculados retorna erro 409 com mensagem explicativa.

---

**História: HU04 – Buscar e filtrar clientes**  
**Descrição:** COMO atendente, QUERO pesquisar clientes por nome ou telefone, PARA localizar rapidamente o tutor no momento do atendimento.  
**Regras de Negócio:**  
- Busca deve ser case-insensitive.  
**Critérios de Aceite:**  
- Lista filtrada exibida em tempo real conforme o usuário digita.

---

#### UC03 – Gerenciar Profissionais

**Objetivo:** Manter os profissionais organizados para compor corretamente os agendamentos e serviços oferecidos.

---

**História: HU05 – Cadastrar profissional**  
**Descrição:** COMO administrador, QUERO cadastrar profissionais com nome, especialidade, telefone e disponibilidade, PARA que possam ser vinculados a agendamentos e serviços.  
**Regras de Negócio:**  
- Nome é obrigatório. O status padrão é "ativo".  
- Um profissional não pode ser excluído se houver agendamentos vinculados.  
**Critérios de Aceite:**  
- Profissional salvo e listado após cadastro.  
- Exclusão bloqueada com agendamentos vinculados.

---

**História: HU06 – Configurar horários de atendimento**  
**Descrição:** COMO profissional, QUERO configurar meus horários de atendimento por dia da semana com hora início, hora fim e duração de cada slot, PARA que o sistema gere automaticamente os horários disponíveis para agendamento.  
**Regras de Negócio:**  
- Apenas um horário por dia da semana por profissional (upsert).  
- Hora fim deve ser posterior a hora início.  
- Slots são gerados dividindo o intervalo pela duração configurada.  
**Critérios de Aceite:**  
- Horários configurados aparecem como chips verdes/cinzas na tela de agendamento.  
- Dia sem horário configurado exibe mensagem "Profissional não atende nesse dia".

---

#### UC04 – Gerenciar Serviços

**Objetivo:** Padronizar o cadastro dos serviços disponíveis com valor, duração e profissional responsável.

---

**História: HU07 – Cadastrar serviço com valor e duração**  
**Descrição:** COMO profissional, QUERO cadastrar meus serviços informando descrição, valor e duração, PARA que clientes visualizem as informações completas no catálogo.  
**Regras de Negócio:**  
- Descrição é obrigatória. Serviço é vinculado automaticamente ao profissional logado.  
- Duração aceita valores: 15, 30, 45, 60, 90, 120 ou 180 minutos.  
- Exclusão bloqueada se houver agendamentos vinculados.  
**Critérios de Aceite:**  
- Serviço salvo e exibido no catálogo com valor e duração formatados.

---

**História: HU08 – Consultar catálogo de serviços (cliente)**  
**Descrição:** COMO cliente, QUERO ver todos os serviços disponíveis com preços e duração, PARA escolher o serviço e agendar diretamente pelo app.  
**Regras de Negócio:**  
- Apenas serviços com status "ativo" são exibidos no catálogo.  
- Filtro por profissional e busca por nome disponíveis.  
**Critérios de Aceite:**  
- Cards exibem nome do serviço, preço (R$), duração (min/h) e profissional responsável.  
- Botão "Agendar" em cada card abre formulário pré-preenchido com serviço e profissional.

---

#### UC05 – Gerenciar Agendamentos

**Objetivo:** Estruturar um controle eficiente de agenda, com slots automáticos, prevenção de conflitos e histórico completo.

---

**História: HU09 – Criar agendamento por slots**  
**Descrição:** COMO cliente ou atendente, QUERO selecionar um profissional, data e um slot disponível, PARA registrar o agendamento sem risco de conflito de horário.  
**Regras de Negócio:**  
- Slots são gerados com base nos horários de trabalho do profissional para a data selecionada.  
- Slots já ocupados (status diferente de "cancelado") são exibidos em cinza e não selecionáveis.  
- O sistema bloqueia duplo agendamento no mesmo horário/profissional na API.  
- No modo cliente: campo de cliente é preenchido automaticamente; campo de status oculto (sempre "agendado").  
- Ao trocar o profissional, os serviços e slots são recarregados automaticamente.  
**Critérios de Aceite:**  
- Agendamento salvo e exibido na lista com status "agendado".  
- Tentativa de agendar em horário ocupado retorna erro 409.

---

**História: HU10 – Atualizar status do agendamento**  
**Descrição:** COMO atendente, QUERO alterar o status do agendamento (agendado, confirmado, cancelado, concluído), PARA manter o histórico atualizado.  
**Regras de Negócio:**  
- O histórico é mantido; agendamentos cancelados liberam o slot para novos agendamentos.  
**Critérios de Aceite:**  
- Status atualizado refletido imediatamente na lista com cor correspondente.

---

**História: HU11 – Consultar agenda filtrada**  
**Descrição:** COMO gestor ou profissional, QUERO consultar agendamentos filtrando por data, profissional, cliente ou status, PARA acompanhar a operação diária.  
**Regras de Negócio:**  
- Filtros são cumulativos e enviados como parâmetros de query para a API.  
**Critérios de Aceite:**  
- Lista atualizada conforme filtro selecionado.

---

## 1.5 Projeto Técnico

### 1.5.1 Arquitetura Utilizada

O PetCare adota uma arquitetura **cliente-servidor em três camadas**, onde a interface mobile/web (Flutter) consome uma API REST (Node.js + Express + TypeScript) que persiste os dados em um banco relacional PostgreSQL.

```
┌─────────────────────────────────────┐
│     Camada de Apresentação          │
│  Flutter/Dart (Mobile + Web)        │
│  Screens → Providers → Services     │
└────────────────┬────────────────────┘
                 │ HTTP/JSON (REST)
                 │ JWT Authentication
┌────────────────▼────────────────────┐
│     Camada de Negócio / API         │
│  Node.js + Express + TypeScript     │
│  Routes → Middlewares → Pool        │
└────────────────┬────────────────────┘
                 │ SQL (pg)
┌────────────────▼────────────────────┐
│     Camada de Persistência          │
│  PostgreSQL                         │
│  Tabelas relacionais com FK         │
└─────────────────────────────────────┘
```

*Figura 2 – Arquitetura cliente-servidor do aplicativo PetCare.*

**Fluxo de autenticação:**
1. Cliente envia e-mail e senha para `POST /api/auth/login`.
2. API valida credenciais, gera token JWT com `id`, `email` e `perfil`.
3. App armazena token em `SharedPreferences` e o envia em todas as requisições via header `Authorization: Bearer <token>`.
4. Middleware `authMiddleware` valida o token antes de processar qualquer rota protegida.

---

### 1.5.2 Ferramentas e Tecnologias

| Ferramenta / Tecnologia | Descrição | Versão | Objetivo |
|------------------------|-----------|--------|---------|
| Flutter | Framework multiplataforma para desenvolvimento mobile e web | Atual (3.x) | Construir a interface do aplicativo e a navegação entre telas |
| Dart | Linguagem principal utilizada no desenvolvimento do app | Atual (3.x) | Implementar lógica, validações, estados e integrações do aplicativo |
| Material Design 3 | Biblioteca visual nativa do ecossistema Flutter | Atual | Padronizar componentes, formulários e experiência de uso no app |
| Node.js | Runtime JavaScript server-side | 18+ LTS | Executar a API REST no servidor |
| Express | Framework web minimalista para Node.js | 4.x | Definir rotas, middlewares e respostas HTTP da API |
| TypeScript | Superset tipado do JavaScript | 5.x | Garantir tipagem estática e segurança no desenvolvimento da API |
| PostgreSQL | Banco de dados relacional robusto | 15+ | Persistir clientes, profissionais, serviços, agendamentos, horários e usuários |
| pg (node-postgres) | Driver PostgreSQL para Node.js | Atual | Conectar e executar queries no banco via pool de conexões |
| JWT (jsonwebtoken) | Padrão de token para autenticação stateless | Atual | Autenticar e autorizar usuários nas requisições à API |
| bcryptjs | Biblioteca de hash de senhas | Atual | Armazenar senhas com segurança usando salt rounds |
| dotenv | Gerenciador de variáveis de ambiente | Atual | Isolar credenciais e configurações do ambiente de produção |
| http (Dart package) | Cliente HTTP para Flutter | Atual | Realizar chamadas REST à API a partir do app |
| shared_preferences | Armazenamento local no Flutter | Atual | Persistir token JWT e dados do usuário logado no device |
| intl (Dart package) | Internacionalização e formatação de datas | Atual | Formatar datas no padrão dd/MM/yyyy no app |
| provider | Gerenciamento de estado no Flutter | Atual | Controlar estado global de autenticação (AuthProvider) |
| Git / GitHub | Controle de versão do projeto | Atual | Rastrear alterações e apoiar colaboração |
| VS Code | Ambiente de desenvolvimento | Atual | Editar, depurar e gerenciar o projeto |

---

### 1.5.3 Modelo Lógico do Banco de Dados

O modelo lógico contempla todas as entidades necessárias para a operação do sistema, refletindo os requisitos priorizados no documento.

```
┌──────────────────┐        ┌──────────────────────┐
│    USUARIOS      │        │     CLIENTES         │
├──────────────────┤   1:1  ├──────────────────────┤
│ PK id            │◄───────│ PK id                │
│    nome          │        │    nome              │
│    email (UNIQUE)│        │    telefone          │
│    senha (hash)  │        │    email             │
│    perfil        │        │    observacoes       │
│    criado_em     │        │    status            │
└──────────────────┘        │    data_cadastro     │
        ▲                   │ FK id_usuario        │
        │ 1:1               └──────────┬───────────┘
        │                              │ 1:N
┌───────┴──────────┐                   │
│  PROFISSIONAIS   │         ┌─────────▼───────────┐
├──────────────────┤         │    AGENDAMENTOS      │
│ PK id            │         ├──────────────────────┤
│    nome          │    1:N  │ PK id                │
│    telefone      ├────────►│ FK id_cliente        │
│    especialidade │         │ FK id_profissional   │
│    disponibilid. │         │ FK id_servico        │
│    status        │         │    data_atendimento  │
│ FK id_usuario    │         │    horario           │
└────────┬─────────┘         │    status            │
         │                   │    observacao        │
         │ 1:N               │    criado_em         │
         ▼                   └──────────────────────┘
┌──────────────────┐                  ▲
│    SERVICOS      │                  │ 1:N
├──────────────────┤         ┌────────┴─────────────┐
│ PK id            ├────────►│  (referência acima)  │
│ FK id_profissio. │         └──────────────────────┘
│    descricao     │
│    valor         │   ┌───────────────────────────────┐
│    duracao_min   │   │    HORARIOS_PROFISSIONAL       │
│    observacao    │   ├───────────────────────────────┤
│    status        │   │ PK id                         │
└──────────────────┘   │ FK id_profissional (CASCADE)  │
                       │    dia_semana (0–6)           │
                       │    hora_inicio                │
┌──────────────────┐   │    hora_fim                   │
│ PASSWORD_RESET_  │   │    intervalo_min              │
│    TOKENS        │   │    ativo                      │
├──────────────────┤   │    UNIQUE(id_prof, dia_semana)│
│ PK id            │   └───────────────────────────────┘
│    email         │
│    token (6 dig) │
│    expira_em     │
│    usado         │
│    criado_em     │
└──────────────────┘
```

*Figura 3 – Modelo lógico do banco de dados do PetCare.*

---

# 2. GESTÃO DE PROJETOS

## 2.1 Cronograma de Codificação do Projeto

| Data | Entrega |
|------|---------|
| 12/04/2026 | Planejamento da implementação, organização do ambiente Flutter + Node.js e revisão final dos requisitos do projeto. |
| 19/04/2026 | Desenvolvimento da estrutura inicial do aplicativo: navegação entre telas, configuração do projeto Flutter e scaffolding da API Express com TypeScript. |
| 26/04/2026 | Implementação do módulo de autenticação: login com JWT, registro de usuários, validação de perfis e redirecionamento por perfil. |
| 03/05/2026 | Implementação do cadastro e gerenciamento de clientes com API REST e persistência no PostgreSQL. |
| 10/05/2026 | Implementação do cadastro e gerenciamento de profissionais com catálogo de visualização para clientes. |
| 17/05/2026 | Implementação do cadastro de serviços com valor, duração e vínculo com profissional; exibição em catálogo para clientes. |
| 24/05/2026 | Desenvolvimento do módulo de agendamentos com controle de horário, status, observações e prevenção de conflitos via API. |
| 31/05/2026 | Implementação de horários de atendimento por profissional e geração automática de slots disponíveis para agendamento. |
| 07/06/2026 | Implementação do Painel do Prestador (módulo exclusivo para profissionais) e Painel do Cliente (catálogo + agendamento direto). Refinamento da interface e padronização visual. |
| 14/06/2026 | Execução de testes funcionais, correção de falhas e estabilização da aplicação. Ajustes de usabilidade e tratamento de erros. |
| 21/06/2026 | Revisão da documentação, atualização final do DVP e consolidação dos artefatos do projeto. |
| 28/06/2026 | Finalização do projeto, geração do PDF final e preparação da apresentação de encerramento. |

---

*Documento gerado em: 06/06/2026*  
*Universidade de Passo Fundo – UPF*  
*Curso: Análise e Desenvolvimento de Sistemas*  
*Aluno: Gustavo Gasparin Grando*

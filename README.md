# Comuh Challenge

Plataforma de comunidades com API REST, interface web e análise de sentimento simples por palavras-chave.

## Stack

- Backend: Ruby on Rails 8.1
- Frontend: ERB, ViewComponent, Stimulus, Turbo/Hotwire
- Banco de dados: PostgreSQL
- Testes: RSpec, Capybara, FactoryBot, SimpleCov
- Linter/segurança: RuboCop Rails Omakase, Brakeman, bundler-audit
- Infra local: Docker Compose

## Requisitos

- Ruby 3.4.8
- PostgreSQL 17 ou Docker
- Node.js 20.19+
- Yarn ou npm

## Setup Local

Copie as variáveis de ambiente:

```bash
cp .env.example .env
```

Instale dependências:

```bash
bundle install
yarn install
```

Prepare o banco:

```bash
bin/rails db:create db:migrate
```

Rode a aplicação:

```bash
bin/dev
```

Acesse:

```text
http://localhost:3000
```

## Docker

Suba PostgreSQL e aplicação:

```bash
docker compose -f docker-compose.dev.yml up --build
```

Para rodar testes no container:

```bash
docker compose -f docker-compose.dev.yml run --rm app bin/rspec
```

## Testes E Qualidade

Rodar a suíte:

```bash
bundle exec rspec
```

Resultado atual:

```text
114 examples, 0 failures
Coverage: 92.46%
```

Rodar linter:

```bash
bundle exec rubocop --format simple
```

Rodar auditorias:

```bash
bin/brakeman --no-pager
bin/bundler-audit
```

## Seeds

O script de seeds popula o banco usando chamadas HTTP para os endpoints da API, conforme solicitado no teste.

Ele cria:

- 5 comunidades
- 50 usuários únicos
- 1000 mensagens, sendo 70% posts e 30% respostas
- 20 IPs únicos
- reações em aproximadamente 80% das mensagens

Execute:

```bash
bin/rails db:seed
```

Por padrão, o seed sobe um servidor local temporário em `127.0.0.1:3099`. Para mudar:

```bash
SEED_API_HOST=127.0.0.1 SEED_API_PORT=3099 bin/rails db:seed
```

## API

### Criar Mensagem

`POST /api/v1/messages`

```json
{
  "username": "john_doe",
  "community_id": "uuid-da-comunidade",
  "content": "Conteudo da mensagem",
  "user_ip": "192.168.1.1",
  "parent_message_id": null
}
```

Regras:

- cria o usuário automaticamente se ele não existir
- calcula `ai_sentiment_score`
- aceita `parent_message_id` para comentários/respostas
- retorna `201 Created`

### Criar Reação

`POST /api/v1/reactions`

```json
{
  "message_id": "uuid-da-mensagem",
  "user_id": "uuid-do-usuario",
  "reaction_type": "like"
}
```

Regras:

- tipos aceitos: `like`, `love`, `insightful`
- existe constraint única em `[message_id, user_id, reaction_type]`
- duplicidade retorna `409 Conflict`
- concorrência é protegida por constraint no banco e tratamento de erro

### Top Mensagens

`GET /api/v1/communities/:id/messages/top?limit=10`

Ranking:

```text
(numero de reacoes * 1.5) + (numero de respostas * 1.0)
```

`limit` tem default `10` e máximo `50`.

### IPs Suspeitos

`GET /api/v1/analytics/suspicious_ips?min_users=3`

Retorna IPs compartilhados por pelo menos `min_users` usuários diferentes.

## Interface Web

Páginas disponíveis:

- `/` ou `/communities`: listagem de comunidades com descrição, total de mensagens e link de acesso
- `/communities/:id`: timeline com as últimas 50 mensagens, formulário de criação e botões de reação
- `/messages/:id`: detalhe da mensagem principal e thread de comentários

Funcionalidades JavaScript:

- criação de mensagem sem reload
- atualização dinâmica da timeline
- limpeza do formulário após sucesso
- reação sem reload
- atualização visual dos contadores
- feedback para reação duplicada

## Análise De Sentimento

A análise de sentimento usa uma implementação simples por palavras-chave em `SentimentAnalyzer`.

O score é normalizado entre `-1.0` e `1.0`:

- positivo: palavras como `ótimo`, `excelente`, `bom`, `love`, `awesome`
- negativo: palavras como `ruim`, `péssimo`, `hate`, `bad`
- neutro: sem palavras reconhecidas

## Deploy Em VPS Privada

O deploy foi feito no render.com. Fluxo recomendado:

1. configurar um novo Web Service (aplicação)
2. configurar um novo Postgres (banco de dados)
3. adicionar `RAILS_MASTER_KEY` e `DATABASE_URL` no Web Services Environment Variables
4. definir `RUN_SEEDS=true` para executar `bin/rails db:seed` automaticamente no deploy
5. depois do primeiro deploy populado, trocar `RUN_SEEDS=false` se quiser evitar reprocessar os seeds

URL de produção:

```text
https://comuh-challenge.onrender.com.
```

## Decisões Técnicas

- UUID como chave primária para entidades principais.
- Constraint única no banco para garantir idempotência/concorrência em reactions.
- Queries dedicadas para ranking e analytics, evitando N+1 nas consultas críticas.
- ViewComponent para componentes reutilizáveis de mensagens, comunidades e badges de sentimento.
- RSpec dividido por models, services, queries, requests, components e system specs.
- Seeds via HTTP para validar o fluxo real da API durante a população inicial.

## Checklist De Entrega

### Repositório & Código

- [x] Código no GitHub público: https://github.com/fabriciobonjorno/comuh
- [x] README com instruções completas
- [x] `.env.example` com variáveis de ambiente
- [x] Linter/formatter configurado
- [x] Código limpo e organizado

### Stack Utilizada

- [x] Backend: Ruby on Rails
- [x] Frontend: ERB + ViewComponent + Stimulus + Turbo/Hotwire
- [x] Banco de dados: PostgreSQL
- [x] Testes: RSpec, Capybara, SimpleCov

### Deploy

- [X] URL da aplicação: https://comuh-challenge.onrender.com
- [X] Seeds executados em produção

### Funcionalidades - API

- [x] `POST /api/v1/messages` cria mensagem e calcula sentiment
- [x] `POST /api/v1/reactions` com proteção de concorrência
- [x] `GET /api/v1/communities/:id/messages/top`
- [x] `GET /api/v1/analytics/suspicious_ips`
- [x] Tratamento de erros apropriado
- [x] Validações implementadas

### Funcionalidades - Frontend

- [x] Listagem de comunidades
- [x] Timeline de mensagens
- [x] Criar mensagem sem reload
- [x] Reagir a mensagens sem reload
- [x] Ver thread de comentários
- [x] Responsivo para mobile e desktop

### Testes

- [x] Cobertura mínima de 70%
- [x] Testes passando
- [x] Como rodar: `bundle exec rspec`

### Documentação

- [x] Setup local documentado
- [x] Decisões técnicas explicadas
- [x] Como rodar seeds
- [x] Endpoints da API documentados
- [ ] Screenshot ou GIF da interface

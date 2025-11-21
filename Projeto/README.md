# GerenciadorEventos — Guia de Containers

Este guia ajuda o time a subir, parar e usar os containers (db, backend e frontend) deste projeto.

## Pré-requisitos
- Docker (Compose v2 já incluso no Docker Desktop e nos pacotes recentes).
- Porta 8081 (backend) e 8088 (frontend) livres no host. O Postgres é publicado no host em 5433 (internamente usa 5432).

## Estrutura
- Compose: `Projeto/docker-compose.yml`
- Credenciais e configs: `Projeto/.env`
- DB Dockerfile e scripts: `Projeto/db/Dockerfile` e `Projeto/db/init-scripts/`
- Backend (Spring Boot): `Projeto/Backend/`
- Frontend (Flutter Web via Nginx): `Projeto/frontend/`

## Subir tudo (modo rápido)
Execute a partir da raiz do repositório:
```bash
# subir e (re)construir imagens
docker compose -f Projeto/docker-compose.yml up -d --build

# verificar status
docker compose -f Projeto/docker-compose.yml ps
```

Alternativa: rodar a partir da pasta `Projeto/`:
```bash
cd Projeto
docker compose up -d --build
```

## Comandos básicos (resumo)
Da raiz do repositório:

```bash
# 1) Build das imagens (sem subir)
docker compose -f Projeto/docker-compose.yml build

# 2) Ligar (subir) os containers em segundo plano
docker compose -f Projeto/docker-compose.yml up -d

# 2.1) Ligar reconstruindo as imagens
docker compose -f Projeto/docker-compose.yml up -d --build

# 3) Desligar (parar) os containers
docker compose -f Projeto/docker-compose.yml stop

# 4) Derrubar tudo (remove containers e rede)
docker compose -f Projeto/docker-compose.yml down
```

## URLs e portas
- Frontend: http://localhost:8088
- Backend:  http://localhost:8081
- Postgres: host=localhost port=5433 (na rede Docker: host=db port=5432)

## Variáveis de ambiente (.env)
Arquivo env enviado no grupo do zap por segurança

## Comandos úteis
Parar containers (mantém rede e volumes):
```bash
docker compose -f Projeto/docker-compose.yml stop
```

Derrubar stack (remove containers e rede, mantém volumes):
```bash
docker compose -f Projeto/docker-compose.yml down
```

Derrubar com remoção do volume de dados (DB novo na próxima subida):
```bash
docker compose -f Projeto/docker-compose.yml down -v
```

Remover containers órfãos (se serviços foram renomeados/removidos):
```bash
docker compose -f Projeto/docker-compose.yml down --remove-orphans
```

Ver logs (tempo real) de um serviço:
```bash
docker compose -f Projeto/docker-compose.yml logs -f backend
```

Ver logs recentes (últimas 100 linhas) de todos os serviços:
```bash
docker compose -f Projeto/docker-compose.yml logs --tail=100
```

Reiniciar serviços sem rebuild:
```bash
docker compose -f Projeto/docker-compose.yml restart
# ou apenas um serviço
docker compose -f Projeto/docker-compose.yml restart backend
```

Rebuild de um serviço específico:
```bash
docker compose -f Projeto/docker-compose.yml build backend
# ou subir já rebuildando
docker compose -f Projeto/docker-compose.yml up -d --build backend
```

Rebuild sem cache (força baixar dependências do zero):
```bash
docker compose -f Projeto/docker-compose.yml build --no-cache backend
```

Executar psql dentro do container do DB:
```bash
docker compose -f Projeto/docker-compose.yml exec db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"
```

Rodar o script de testes 99-tests.sql (já copiado para a imagem em /docker-entrypoint-initdb.d/):
```bash
# opção A: usando o arquivo já presente dentro do container
docker exec -i gerenciador-db \
  psql -U admin -d meu_banco \
  -f /docker-entrypoint-initdb.d/99-tests.sql

# opção B: redirecionando do arquivo local do repo
docker exec -i gerenciador-db \
  psql -U admin -d meu_banco \
  < "$(pwd)/Projeto/db/init-scripts/99-tests.sql"
```

## Troubleshooting
- Erro "port is already allocated":
  - 8081/8088/5433 podem estar em uso. Altere o mapeamento em `docker-compose.yml` (ex.: `8089:80`) ou libere a porta.
- H2 vs Postgres:
  - O backend agora usa Postgres por padrão. As credenciais vêm do `.env` via `SPRING_DATASOURCE_*`.
- Scripts de init do Postgres:
  - São executados automaticamente só no primeiro start do volume de dados. Para reaplicar do zero, use `down -v` e `up -d --build` novamente.

## Limpeza de cache (opcional)
```bash
# limpa cache de build do Docker
docker builder prune --all --force
```

Limpar imagens não usadas (dangling e não referenciadas):
```bash
docker image prune -a -f
```

Limpar volumes não usados (atenção: pode remover dados de bancos de containers parados):
```bash
docker volume prune -f
```

Limpeza geral (containers/parados, redes não usadas, imagens dangling e build cache):
```bash
docker system prune -a -f
```

Remover volume de dados do Postgres explicitamente (dados serão perdidos):
```bash
docker volume rm gerenciador-eventos_db-data || true
```

Listar containers, volumes e redes:
```bash
docker ps -a
docker volume ls
docker network ls
```

Entrar no shell do container (debug):
```bash
# backend (sh)
docker exec -it gerenciador-backend sh
# db (sh)
docker exec -it gerenciador-db sh
# frontend (sh)
docker exec -it gerenciador-frontend sh
```

Backup e restore do Postgres:
```bash
# Backup
docker exec -t gerenciador-db pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" > backup.sql

# Restore
cat backup.sql | docker exec -i gerenciador-db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"
```

Checagens rápidas de saúde e portas:
```bash
# health log do db
docker inspect --format '{{range .State.Health.Log}}{{.Output}}{{end}}' gerenciador-db

# testar backend HTTP
curl -i http://localhost:8081 || true

# verificar portas em uso (Linux)
ss -ltnp | grep -E ':(8081|8088|5433)'
```

## Nomes de recursos
- Containers: `gerenciador-db`, `gerenciador-backend`, `gerenciador-frontend`
- Rede: `gerenciador-net`
- Volume de dados do Postgres: `db-data` (nome lógico do compose)

# syntax=docker/dockerfile:1

# ── Stage 1: dependências ─────────────────────────────────
FROM node:20-alpine AS deps
WORKDIR /app
COPY app/package*.json ./
# Instala apenas dependências de produção
RUN npm install --omit=dev

# ── Stage 2: runtime ──────────────────────────────────────
FROM node:20-alpine AS runtime
WORKDIR /app

# Usuário não-root (o node:alpine já traz o usuário "node")
ENV NODE_ENV=production

# Copia node_modules do stage anterior e o código da aplicação
COPY --from=deps /app/node_modules ./node_modules
COPY app/ ./

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', r => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"

USER node

CMD ["node", "server.js"]

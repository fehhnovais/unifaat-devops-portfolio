# Imagem base enxuta
FROM node:20-alpine

WORKDIR /app

# Copia manifestos e instala apenas dependências de produção
COPY package*.json ./
RUN npm install --production

# Copia o código da aplicação
COPY . .

EXPOSE 3000

# Healthcheck do container
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', r => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"

CMD ["node", "server.js"]

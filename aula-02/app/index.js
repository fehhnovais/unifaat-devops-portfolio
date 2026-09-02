const express = require('express');
const { Pool } = require('pg');
const redis = require('redis');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware para JSON
app.use(express.json());

// Configuração do PostgreSQL
const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});

// Configuração do Redis
const redisClient = redis.createClient({
  socket: {
    host: process.env.REDIS_HOST,
    port: process.env.REDIS_PORT || 6379,
  }
});

// Conectar ao Redis
(async () => {
  try {
    await redisClient.connect();
    console.log('✅ Conectado ao Redis');
  } catch (err) {
    console.error('❌ Erro ao conectar ao Redis:', err);
  }
})();

// Testar conexão com PostgreSQL
pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('❌ Erro ao conectar ao PostgreSQL:', err);
  } else {
    console.log('✅ Conectado ao PostgreSQL:', res.rows[0].now);
  }
});

// Endpoint de healthcheck
app.get('/health', async (req, res) => {
  try {
    // Verificar PostgreSQL
    await pool.query('SELECT 1');
    
    // Verificar Redis
    await redisClient.ping();
    
    res.status(200).json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      services: {
        postgres: 'connected',
        redis: 'connected'
      }
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      error: error.message
    });
  }
});

// Endpoint raiz
app.get('/', (req, res) => {
  res.json({
    message: 'API Node.js com Express, PostgreSQL e Redis',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      users: '/users',
      cache: '/cache/:key'
    }
  });
});

// Exemplo de endpoint com PostgreSQL
app.get('/users', async (req, res) => {
  try {
    const result = await pool.query('SELECT current_database(), current_user');
    res.json({
      database: result.rows[0].current_database,
      user: result.rows[0].current_user,
      message: 'Conexão com PostgreSQL funcionando!'
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Exemplo de endpoint com Redis (SET)
app.post('/cache/:key', async (req, res) => {
  try {
    const { key } = req.params;
    const { value, ttl } = req.body;
    
    if (ttl) {
      await redisClient.setEx(key, ttl, JSON.stringify(value));
    } else {
      await redisClient.set(key, JSON.stringify(value));
    }
    
    res.json({
      message: 'Valor armazenado no cache',
      key,
      value
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Exemplo de endpoint com Redis (GET)
app.get('/cache/:key', async (req, res) => {
  try {
    const { key } = req.params;
    const value = await redisClient.get(key);
    
    if (value) {
      res.json({
        key,
        value: JSON.parse(value),
        cached: true
      });
    } else {
      res.status(404).json({
        message: 'Chave não encontrada no cache'
      });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`🚀 Servidor rodando na porta ${PORT}`);
  console.log(`📍 http://localhost:${PORT}`);
  console.log(`💚 Health check: http://localhost:${PORT}/health`);
});

// Tratamento de erros
process.on('SIGTERM', async () => {
  console.log('SIGTERM recebido, encerrando...');
  await redisClient.quit();
  await pool.end();
  process.exit(0);
});

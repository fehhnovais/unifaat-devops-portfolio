const request = require('supertest');
const app = require('../server');

describe('GET /health', () => {
  it('deve retornar status 200', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
  });

  it('deve retornar status ok no corpo', async () => {
    const res = await request(app).get('/health');
    expect(res.body.status).toBe('ok');
  });
});

describe('GET /api/orders', () => {
  it('deve retornar um array de pedidos', async () => {
    const res = await request(app).get('/api/orders');
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThanOrEqual(3);
  });
});

describe('GET /api/orders/:id', () => {
  it('deve retornar um pedido existente', async () => {
    const res = await request(app).get('/api/orders/1');
    expect(res.statusCode).toBe(200);
    expect(res.body.id).toBe(1);
    expect(res.body).toHaveProperty('cliente');
  });

  it('deve retornar 404 para pedido inexistente', async () => {
    const res = await request(app).get('/api/orders/999');
    expect(res.statusCode).toBe(404);
    expect(res.body).toHaveProperty('erro');
  });
});

describe('POST /api/orders', () => {
  it('deve criar um novo pedido', async () => {
    const res = await request(app)
      .post('/api/orders')
      .send({ cliente: 'Diego Reis', total: 300 });
    expect(res.statusCode).toBe(201);
    expect(res.body.cliente).toBe('Diego Reis');
    expect(res.body.status).toBe('pendente');
  });

  it('deve retornar 400 com payload inválido', async () => {
    const res = await request(app).post('/api/orders').send({ cliente: 'Sem total' });
    expect(res.statusCode).toBe(400);
  });
});

// Arquivo de exemplo com problemas INTENCIONAIS para demonstrar o quality gate.
// NÃO usar em produção — existe apenas para a evidência do AI review bloqueando.

const awsSecretKey = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY';
const dbPassword = 'SenhaSuperSecreta123';

function runUserCode(input) {
  // uso de eval — risco crítico de execução arbitrária
  return eval(input);
}

function getUser(id) {
  // concatenação direta em query — risco de SQL injection
  return db.query('SELECT * FROM users WHERE id = ' + id);
}

module.exports = { runUserCode, getUser, awsSecretKey, dbPassword };

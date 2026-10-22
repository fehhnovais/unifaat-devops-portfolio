# RESPOSTAS — Aula 08: GitHub Actions e CI Pipelines

**Aluno:** FERNANDA TAVARES
**RA:** 4025109

---

## 1. O que é CI (Integração Contínua) e qual problema ela resolve na TechNova?

CI é a prática de integrar e **verificar o código automaticamente** a cada push ou Pull
Request. No caso da TechNova, o deploy era manual (32 minutos, propenso a erro) e não havia
checagem de qualidade — um bug chegou a produção porque os testes foram esquecidos. Com CI,
lint, testes e build rodam sozinhos em cada mudança: se algo quebra, o PR é bloqueado e o
desenvolvedor é avisado **antes** de o problema chegar à produção.

## 2. Diferencie workflow, job, step e runner.

- **Workflow:** o arquivo YAML em `.github/workflows/` que descreve toda a automação (a "receita").
- **Job:** um conjunto de steps que roda em um mesmo runner. Jobs podem rodar em paralelo ou em sequência (com `needs`).
- **Step:** uma ação individual dentro de um job — pode ser `uses` (action pronta) ou `run` (comando shell).
- **Runner:** a máquina virtual que executa o job (neste projeto, `ubuntu-latest`).

## 3. Para que serve a keyword `needs`? Como foi usada neste TF?

`needs` cria **dependência entre jobs**: um job só executa se o(s) job(s) listados em `needs`
passarem. Neste TF o encadeamento é `lint → test → build`:

- `test` tem `needs: lint`
- `build` tem `needs: [lint, test]`

Assim o build só acontece se o lint e os testes passarem, economizando tempo e evitando
builds de código quebrado.

## 4. O que o ESLint verifica? Cite 3 regras usadas.

O ESLint faz **análise estática**: detecta variáveis não usadas, imports desnecessários,
erros de sintaxe e padrões inconsistentes, antes mesmo de executar o código. Regras usadas no
`.eslintrc.json`:

- `"semi": ["error", "always"]` — exige ponto-e-vírgula
- `"quotes": ["error", "single"]` — exige aspas simples
- `"no-unused-vars": "warn"` — alerta sobre variáveis não utilizadas

## 5. Por que o `package-lock.json` é importante para o `npm ci` no CI?

`npm ci` instala **exatamente** as versões travadas no `package-lock.json`, garantindo builds
reprodutíveis e mais rápidos. Se o lockfile não existir, o `npm ci` falha. Por isso ele foi
commitado junto do projeto. É também pré-requisito para o cache do `setup-node`.

## 6. Como os GitHub Secrets protegem credenciais? Cite as regras de segurança.

Secrets são variáveis **criptografadas** armazenadas no GitHub, referenciadas por
`${{ secrets.NOME }}`. Regras importantes:

- São **mascarados** nos logs (aparecem como `***`).
- **Não** são repassados a workflows disparados por forks (protege PRs de terceiros).
- **Não** podem ser lidos depois de criados (apenas atualizados ou deletados).
- Limite de ~48 KB por secret.

Neste TF, `AWS_REGION` é usado via `env: AWS_REGION: ${{ secrets.AWS_REGION }}` no job `build`.

## 7. O que é o `GITHUB_TOKEN`?

É um token **gerado automaticamente** para cada execução do workflow, usado para interagir com
a API do GitHub (comentar em PRs, criar releases, ler o repositório). Neste TF ele é usado no
job `pr-comment` para postar o resultado do CI no Pull Request. Ele tem escopo limitado ao
próprio repositório e expira ao fim da execução.

## 8. O que são Environments e Protection Rules?

Environments separam configuração por estágio (ex.: `staging`, `production`) e permitem
**protection rules**: revisores obrigatórios (approval gate), wait timer, restrição de branches
e secrets exclusivos daquele ambiente. Servem para impedir que alguém faça deploy direto em
produção sem aprovação.

## 9. Por que usar repositório público para GitHub Actions neste curso?

Repositórios **públicos** têm **minutos ilimitados e gratuitos** de GitHub Actions, enquanto
repositórios privados no plano Free têm 2.000 minutos/mês. Para os labs da disciplina, público
evita qualquer custo.

## 10. Bônus implementados neste TF

| Bônus | Onde |
|-------|------|
| B1 — Matrix strategy (Node 18 e 20) | job `test` |
| B2 — Cache de dependências | `setup-node` com `cache: npm` |
| B3 — Comentário automático no PR | job `pr-comment` |
| B4 — Concurrency control | bloco `concurrency` no topo do workflow |
| B5 — Smoke test no Docker | step "Smoke test do container" no job `build` |

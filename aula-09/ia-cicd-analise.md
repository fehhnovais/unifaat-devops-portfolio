# Análise — Docker Registry (ECR) e IA no CI/CD

**Aluno:** FERNANDA TAVARES — **RA:** 4025109

---

## 1. Por que Amazon ECR como registry?

O projeto usa o **Amazon ECR** em vez de alternativas como GitHub Container Registry
(ghcr.io) ou Docker Hub pelos seguintes motivos:

- **Mesmo ecossistema da infra:** a TechNova já roda na AWS (EC2/ECS, RDS, VPC das aulas
  anteriores). Manter as imagens no ECR deixa o pull local à infra, com menor latência e sem
  sair da conta AWS.
- **Autenticação integrada ao IAM:** o acesso é controlado pelas credenciais da própria
  sessão AWS, sem precisar gerenciar tokens de terceiros.
- **Scan de vulnerabilidades nativo:** o ECR oferece *scan on push* sem configuração extra.
- **Preparação para deploy:** nas próximas aulas (Blue-Green, Canary) o deploy em EC2/ECS
  faz pull direto do ECR — é o caminho natural.

### Restrições do AWS Academy Learner Lab

- As credenciais da sessão são **temporárias** e incluem um `aws_session_token`. Elas
  **expiram a cada sessão** do Lab, então um workflow de CI com secrets fixos quebra assim que
  a sessão encerra. Por isso o **fluxo confiável é o `ecr-push.sh` local**, executado com a
  sessão ativa; o `ci-ecr-aula09.yml` é opcional e só funciona enquanto os secrets estiverem
  válidos.
- O Lab **permite criar repositórios ECR**, mas **não permite criar usuários/grupos/roles
  IAM**. Por isso a autenticação usa as credenciais da sessão, não um usuário dedicado.
- Região fixa: **us-east-1**.

## 2. Estratégia de tagging

Cada push publica a imagem com múltiplas tags, cada uma com um propósito:

| Tag | Exemplo | Para que serve |
|-----|---------|----------------|
| `sha-<short>` | `sha-a1b2c3d` | **Rastreabilidade e rollback.** Aponta para um commit exato; imutável na prática. |
| `latest` | `latest` | **Conveniência.** Sempre a última build — nunca usar para rollback. |
| Semver | `1.2.3`, `1.2`, `1` | **Releases.** Gerado a partir da git tag `v1.2.3`. Permite fixar `1.2` e receber patches. |

O `sha-` é a base do rollback: para voltar uma versão, basta
`docker pull <uri>:sha-<commit_antigo>`. O semver só é publicado quando o commit tem uma git
tag `v*.*.*`, evitando poluir o registry em commits comuns.

## 3. Padrões que o AI review detecta

O script `.github/scripts/ai-review.js` inspeciona apenas as **linhas adicionadas** do diff do
PR e classifica achados em CRITICAL / WARNING / INFO:

| Severidade | Regra | O que detecta |
|------------|-------|---------------|
| 🔴 CRITICAL | `secret-hardcoded` | Chaves/senhas/tokens embutidos (inclui padrão `AKIA...`) |
| 🔴 CRITICAL | `eval-usage` | Uso de `eval()` |
| 🔴 CRITICAL | `sql-injection` | Query SQL concatenada com variável |
| 🔴 CRITICAL | `child-process` | Execução de comando do SO (`exec`/`spawn`) |
| 🟡 WARNING | `console-log` | `console.log/debug` esquecido |
| 🟡 WARNING | `empty-catch` | Bloco `catch` vazio (erro silenciado) |
| 🟡 WARNING | `http-insecure` | URL `http://` sem TLS |
| 🟡 WARNING | `debugger` | Instrução `debugger` esquecida |
| 🔵 INFO | `todo-fixme` | Comentário TODO/FIXME |
| 🔵 INFO | `var-usage` | Uso de `var` (preferir const/let) |

São **10 regras** (acima do mínimo de 5, atendendo também o bônus de 8+ padrões).

## 4. Lógica da análise (prompt/regras)

A abordagem é **baseada em regras determinísticas** (regex por linha adicionada), que simula o
papel de um revisor de IA focado em segurança e higiene de código. A lógica:

1. Parse do diff unificado → extrai somente linhas que começam com `+` (ignora remoções e
   contexto) e rastreia arquivo + número de linha.
2. Ignora arquivos não-código (`.md`, `.json`, `.lock`, imagens).
3. Cada regra roda contra cada linha; achados são acumulados.
4. Monta um comentário em Markdown (tabela ordenada por severidade).
5. **Quality gate:** se houver ≥1 CRITICAL → `exit 1` (bloqueia o PR). Caso contrário `exit 0`.

> Caso seja integrado a um LLM (ex.: Amazon Bedrock), o mesmo diff seria enviado com um prompt
> do tipo: *"Você é um revisor de segurança. Analise apenas as linhas adicionadas e liste
> achados por severidade (CRITICAL/WARNING/INFO), com arquivo, linha e justificativa."* As
> regras atuais documentam exatamente o que esperar desse revisor.

## 5. Quando confiar na IA vs. exigir review humano

- **Confiar (automatizar):** detecção de padrões objetivos — secrets hardcoded, `eval`,
  `console.log`, `var`, `debugger`. São de baixa ambiguidade e alto valor como primeira linha
  de defesa.
- **Exigir humano:** decisões de arquitetura, regras de negócio, trade-offs de performance,
  contexto entre múltiplos arquivos e mudanças em segurança/autenticação. A IA aqui é um
  **filtro inicial**, não a aprovação final.

## 6. Limitações identificadas

- **Falsos positivos:** `sql-injection` dispara em qualquer string SQL concatenada, mesmo que
  a variável seja segura; `secret-hardcoded` pode pegar exemplos/fixtures.
- **Falsos negativos:** a análise por regex não entende semântica — um secret montado em
  partes ou uma injeção indireta passa despercebido.
- **Contexto limitado:** olha linha a linha, sem o arquivo inteiro nem o histórico. Não
  entende fluxo de dados entre funções/arquivos.
- **Só linhas adicionadas:** problemas pré-existentes no código não tocado pelo PR não são
  reportados (por design, para focar na mudança).

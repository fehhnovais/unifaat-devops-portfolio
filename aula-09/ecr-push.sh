#!/usr/bin/env bash
#
# ecr-push.sh — Build e push da imagem TechNova API para o Amazon ECR.
#
# Fluxo:
#   1. Descobre o Account ID da sessão (credenciais do Learner Lab)
#   2. Cria/garante o repositório ECR "technova-api" (idempotente)
#   3. (bônus) Habilita scan-on-push e aplica lifecycle policy
#   4. Faz login no ECR via docker login
#   5. Builda a imagem (Dockerfile multi-stage)
#   6. Faz push com as tags: sha-<short>, latest e semver (se houver git tag v*.*.*)
#
# Pré-requisitos: aws cli v2, docker, git, e credenciais do Learner Lab
# carregadas na sessão (aws configure / variáveis de ambiente com session token),
# sempre na região us-east-1.
#
# Uso:
#   ./ecr-push.sh
#
set -euo pipefail

# ── Configuração ──────────────────────────────────────────
AWS_REGION="${AWS_REGION:-us-east-1}"
REPO_NAME="${REPO_NAME:-technova-api}"

echo "==> Região: ${AWS_REGION} | Repositório: ${REPO_NAME}"

# ── 1. Account ID da sessão ───────────────────────────────
echo "==> Descobrindo Account ID da sessão..."
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
if [ -z "${ACCOUNT_ID}" ]; then
  echo "ERRO: não foi possível obter o Account ID. As credenciais do Lab expiraram?" >&2
  exit 1
fi
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
IMAGE_URI="${REGISTRY}/${REPO_NAME}"
echo "    Account ID: ${ACCOUNT_ID}"
echo "    Registry  : ${REGISTRY}"

# ── 2. Criar/garantir o repositório ECR (idempotente) ─────
echo "==> Garantindo que o repositório ECR existe..."
if aws ecr describe-repositories --repository-names "${REPO_NAME}" --region "${AWS_REGION}" >/dev/null 2>&1; then
  echo "    Repositório já existe."
else
  echo "    Criando repositório com scan-on-push habilitado..."
  aws ecr create-repository \
    --repository-name "${REPO_NAME}" \
    --image-scanning-configuration scanOnPush=true \
    --region "${AWS_REGION}" >/dev/null
  echo "    Repositório criado."
fi

# ── 3. (bônus) Lifecycle policy: mantém só as 10 últimas e expira untagged ─
echo "==> Aplicando lifecycle policy (bônus)..."
aws ecr put-lifecycle-policy \
  --repository-name "${REPO_NAME}" \
  --region "${AWS_REGION}" \
  --lifecycle-policy-text file://ecr-lifecycle-policy.json >/dev/null 2>&1 \
  && echo "    Lifecycle policy aplicada." \
  || echo "    AVISO: não foi possível aplicar a lifecycle policy (seguindo mesmo assim)."

# ── 4. Login no ECR ───────────────────────────────────────
echo "==> Autenticando no ECR..."
aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin "${REGISTRY}"

# ── 5. Resolver as tags ───────────────────────────────────
SHORT_SHA="$(git rev-parse --short HEAD)"
SHA_TAG="sha-${SHORT_SHA}"

# Tag semver a partir da git tag v*.*.* mais recente (se existir)
SEMVER_TAGS=()
if GIT_TAG="$(git describe --tags --exact-match 2>/dev/null)"; then
  if [[ "${GIT_TAG}" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    MAJOR="${BASH_REMATCH[1]}"
    MINOR="${BASH_REMATCH[2]}"
    PATCH="${BASH_REMATCH[3]}"
    SEMVER_TAGS=("${MAJOR}.${MINOR}.${PATCH}" "${MAJOR}.${MINOR}" "${MAJOR}")
    echo "    Git tag detectada: ${GIT_TAG} -> semver ${SEMVER_TAGS[*]}"
  fi
else
  echo "    Nenhuma git tag v*.*.* no commit atual — publicando apenas sha + latest."
fi

ALL_TAGS=("${SHA_TAG}" "latest" "${SEMVER_TAGS[@]}")

# ── 6. Build ──────────────────────────────────────────────
echo "==> Build da imagem Docker..."
docker build -t "${REPO_NAME}:${SHA_TAG}" .

# Aplica todas as tags e faz push
echo "==> Tagueando e publicando..."
for TAG in "${ALL_TAGS[@]}"; do
  docker tag "${REPO_NAME}:${SHA_TAG}" "${IMAGE_URI}:${TAG}"
  docker push "${IMAGE_URI}:${TAG}"
  echo "    Publicado: ${IMAGE_URI}:${TAG}"
done

echo ""
echo "✅ Push concluído."
echo "   Para fazer pull (rollback por tag):"
echo "     docker pull ${IMAGE_URI}:${SHA_TAG}"
echo "     docker pull ${IMAGE_URI}:latest"

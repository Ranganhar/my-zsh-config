#!/usr/bin/env bash
set -Eeuo pipefail

IMAGE_NAME="${IMAGE_NAME:-ranganhar-super-image}"
CONTAINER_NAME="${CONTAINER_NAME:-ranganhar-super-container}"
NETWORK_NAME="${NETWORK_NAME:-ranganhar-super-bridge}"

USER_NAME="${USER_NAME:-ranganhar}"
USER_PASSWD="${USER_PASSWD:-ranganhar}"

HOST_MOUNT="${HOST_MOUNT:-/home/runhangg/super}"
CONTAINER_MOUNT="${CONTAINER_MOUNT:-/home/${USER_NAME}/file}"

DOCKERFILE="${DOCKERFILE:-Dockerfile}"
SSH_PORT="${SSH_PORT:-2222}"
SHM_SIZE="${SHM_SIZE:-64g}"

RECREATE="${RECREATE:-1}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[ERROR] command not found: $1"
    exit 1
  fi
}

require_cmd docker
require_cmd python3

if ! docker info >/dev/null 2>&1; then
  echo "[ERROR] Docker daemon is not available. Check docker service or user permission."
  exit 1
fi

if [[ ! -f "${DOCKERFILE}" ]]; then
  echo "[ERROR] Dockerfile not found: ${DOCKERFILE}"
  exit 1
fi

if [[ ! -d "${HOST_MOUNT}" ]]; then
  echo "[ERROR] host mount directory does not exist: ${HOST_MOUNT}"
  echo "Create it first:"
  echo "  mkdir -p ${HOST_MOUNT}"
  exit 1
fi

echo "[INFO] image name      : ${IMAGE_NAME}"
echo "[INFO] container name  : ${CONTAINER_NAME}"
echo "[INFO] network name    : ${NETWORK_NAME}"
echo "[INFO] user name       : ${USER_NAME}"
echo "[INFO] host mount      : ${HOST_MOUNT}"
echo "[INFO] container mount : ${CONTAINER_MOUNT}"
echo "[INFO] ssh port        : ${SSH_PORT}"
echo

echo "[STEP 1] Building Docker image..."
docker build \
  -t "${IMAGE_NAME}" \
  -f "${DOCKERFILE}" \
  --build-arg USER_NAME="${USER_NAME}" \
  --build-arg USER_PASSWD="${USER_PASSWD}" \
  .

echo
echo "[STEP 2] Preparing Docker bridge network..."

network_exists() {
  docker network inspect "$1" >/dev/null 2>&1
}

get_existing_docker_subnets() {
  docker network inspect $(docker network ls -q) \
    --format '{{range .IPAM.Config}}{{if .Subnet}}{{.Subnet}}{{"\n"}}{{end}}{{end}}' \
    2>/dev/null | sort -u || true
}

get_host_route_subnets() {
  if command -v ip >/dev/null 2>&1; then
    ip -o route show |
      awk '{print $1}' |
      grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$' |
      sort -u || true
  fi
}

choose_available_subnet() {
  local used_file
  used_file="$(mktemp)"

  {
    get_existing_docker_subnets
    get_host_route_subnets
  } | sort -u >"${used_file}"

  python3 - "${used_file}" <<'PY'
import ipaddress
import sys

used_file = sys.argv[1]

used = []
with open(used_file, "r", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            used.append(ipaddress.ip_network(line, strict=False))
        except ValueError:
            pass

candidates = []

# Docker 常用私有网段，避开默认 172.17.0.0/16，从 172.18 开始尝试
for i in range(18, 32):
    candidates.append(f"172.{i}.0.0/16")

# 备用 10.x 网段，通常适合实验室服务器
for i in range(64, 128):
    candidates.append(f"10.{i}.0.0/16")

# 再备用 192.168.x.0/24
for i in range(100, 255):
    candidates.append(f"192.168.{i}.0/24")

for c in candidates:
    net = ipaddress.ip_network(c, strict=False)
    if all(not net.overlaps(u) for u in used):
        print(str(net))
        sys.exit(0)

sys.exit(1)
PY

  rm -f "${used_file}"
}

if network_exists "${NETWORK_NAME}"; then
  NETWORK_DRIVER="$(docker network inspect "${NETWORK_NAME}" -f '{{.Driver}}')"
  if [[ "${NETWORK_DRIVER}" != "bridge" ]]; then
    echo "[ERROR] network ${NETWORK_NAME} already exists but is not bridge. Driver: ${NETWORK_DRIVER}"
    exit 1
  fi

  NETWORK_SUBNET="$(docker network inspect "${NETWORK_NAME}" -f '{{range .IPAM.Config}}{{.Subnet}}{{end}}')"
  echo "[INFO] Reusing existing bridge network: ${NETWORK_NAME}, subnet: ${NETWORK_SUBNET}"
else
  NETWORK_SUBNET="$(choose_available_subnet || true)"

  if [[ -z "${NETWORK_SUBNET}" ]]; then
    echo "[ERROR] failed to find an available Docker subnet."
    exit 1
  fi

  echo "[INFO] Creating bridge network: ${NETWORK_NAME}, subnet: ${NETWORK_SUBNET}"

  docker network create \
    --driver bridge \
    --attachable \
    --subnet "${NETWORK_SUBNET}" \
    "${NETWORK_NAME}"
fi

echo
echo "[STEP 3] Removing existing container if needed..."

if docker ps -a --format '{{.Names}}' | grep -Fxq "${CONTAINER_NAME}"; then
  if [[ "${RECREATE}" == "1" ]]; then
    echo "[INFO] Removing old container: ${CONTAINER_NAME}"
    docker rm -f "${CONTAINER_NAME}"
  else
    echo "[ERROR] container already exists: ${CONTAINER_NAME}"
    echo "Set RECREATE=1 to remove and recreate it."
    exit 1
  fi
fi

echo
echo "[STEP 4] Starting container..."

docker run -dit \
  --name "${CONTAINER_NAME}" \
  --gpus all \
  --network "${NETWORK_NAME}" \
  --ipc=host \
  --shm-size="${SHM_SIZE}" \
  -v "${HOST_MOUNT}:${CONTAINER_MOUNT}" \
  -p "${SSH_PORT}:22" \
  "${IMAGE_NAME}"

echo
echo "[STEP 5] Verifying container..."

docker ps --filter "name=${CONTAINER_NAME}"

echo
echo "[INFO] Container user/home check:"
docker exec -u "${USER_NAME}" "${CONTAINER_NAME}" bash -lc "
whoami
echo \$HOME
ls -ld '${CONTAINER_MOUNT}'
"

echo
echo "[INFO] Docker network:"
docker network inspect "${NETWORK_NAME}" \
  --format 'Name={{.Name}} Driver={{.Driver}} Subnet={{range .IPAM.Config}}{{.Subnet}}{{end}} Gateway={{range .IPAM.Config}}{{.Gateway}}{{end}}'

echo
echo "[INFO] GPU check:"
if docker exec "${CONTAINER_NAME}" bash -lc 'nvidia-smi' >/dev/null 2>&1; then
  docker exec "${CONTAINER_NAME}" bash -lc 'nvidia-smi'
else
  echo "[WARN] nvidia-smi failed inside container."
  echo "[WARN] Check whether NVIDIA Container Toolkit is installed on the host."
fi

echo
echo "[DONE] Container is ready."
echo
echo "Enter container:"
echo "  docker exec -it -u ${USER_NAME} ${CONTAINER_NAME} bash"
echo
echo "SSH login:"
echo "  ssh -p ${SSH_PORT} ${USER_NAME}@localhost"

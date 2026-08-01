ENV_FILE="${ENV_FILE:-keycloak.env}"
IMAGE="${KEYCLOAK_IMAGE:-quay.io/keycloak/keycloak:26.7.0}"
HOST_PORT="${HOST_PORT:-9081}"
KEYCLOAK_HOSTNAME="${KEYCLOAK_HOSTNAME:-http://localhost:${HOST_PORT}}"

if [ ! -f "$ENV_FILE" ]; then
  echo "Not found $ENV_FILE"
  echo "Run: cp keycloak.env.example keycloak.env"
  exit 1
fi

docker pull "$IMAGE"

docker rm -f keycloak 2>/dev/null || true

docker run -d \
  --name keycloak \
  --restart unless-stopped \
  --add-host host.docker.internal:host-gateway \
  -p "127.0.0.1:${HOST_PORT}:8080" \
  --env-file ./keycloak.env \
  -e KC_HOSTNAME="${KEYCLOAK_HOSTNAME}" \
  quay.io/keycloak/keycloak:26.7.0 \
  start

echo "Keycloak running..."
docker logs -f keycloak
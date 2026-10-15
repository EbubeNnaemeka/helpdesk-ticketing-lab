#!/usr/bin/env bash
# Turns on the GLPI REST API for this lab and creates an API client for the Docker host,
# protected by a random app token. Run from the repo root after `docker compose up -d`.
set -euo pipefail

DB_PASS=$(grep '^GLPI_DB_PASSWORD=' .env | cut -d= -f2)
APP_TOKEN=$(openssl rand -hex 20)

docker compose exec -T glpi sh -c '
  cd /var/www/glpi &&
  php bin/console config:set enable_api 1 &&
  php bin/console config:set enable_api_login_credentials 1' >/dev/null

# GLPI stores app tokens encrypted with its own key (same method as GLPIKey::encrypt).
ENC_TOKEN=$(docker compose exec -T glpi php -r '
  $key = file_get_contents("/var/glpi/config/glpicrypt.key");
  $nonce = random_bytes(SODIUM_CRYPTO_AEAD_XCHACHA20POLY1305_IETF_NPUBBYTES);
  echo base64_encode($nonce . sodium_crypto_aead_xchacha20poly1305_ietf_encrypt($argv[1], $nonce, $nonce, $key));' "$APP_TOKEN")

# Requests from the Mac arrive from the Docker bridge network (172.16.0.0/12), not 127.0.0.1.
docker compose exec -T db mysql -uglpi -p"$DB_PASS" glpi -e "
  DELETE FROM glpi_apiclients WHERE name = 'lab host (docker bridge)';
  INSERT INTO glpi_apiclients (entities_id, is_recursive, name, is_active, ipv4_range_start, ipv4_range_end, app_token, app_token_date, dolog_method, comment, date_mod, date_creation)
  VALUES (0, 1, 'lab host (docker bridge)', 1, INET_ATON('172.16.0.0'), INET_ATON('172.31.255.255'), '$ENC_TOKEN', NOW(), 0, 'Created by scripts/enable-api.sh', NOW(), NOW());" 2>/dev/null

echo "API enabled. App token (keep it out of git):"
echo "$APP_TOKEN"

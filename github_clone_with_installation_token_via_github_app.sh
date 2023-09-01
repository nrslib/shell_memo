#!/usr/bin/env bash

set -euox pipefail

organization_name=<your organization name>
target_repository=<target repository name>
github_app_id=<your github app id>
github_app_key_path=<github pem file>

datetime_now=$(date "+%s")
iat=$((${datetime_now} - 60))
exp=$((${datetime_now} + (10 * 60)))

header=$(echo -n '{"alg":"RS256","typ":"JWT"}' | base64 -w 0)

cat << EOF > jwt.json
{
  "iat": $iat,
  "exp": $exp,
  "iss": $github_app_id
}
EOF

payload=$( jq . jwt.json | base64 -w 0 )
rm jwt.json

unsigned_token="${header}.${payload}"
signed_token=$(echo -n "${unsigned_token}" | openssl dgst -binary -sha256 -sign "${github_app_key_path}" | base64 -w 0)

jwt="${unsigned_token}.${signed_token}"

installation_id=$(curl -s -X GET \
 -H "Accept: application/vnd.github+json" \
 -H "Authorization: Bearer ${jwt}" \
 -H "X-GitHub-Api-Version: 2022-11-28" \
 "https://api.github.com/app/installations" | jq -r ".[] | select(.account.login == \"${organization_name}\") | .id")

installation_token=$(curl --request POST \
 -H "Accept: application/vnd.github+json" \
 -H "Authorization: Bearer ${jwt}" \
 -H "X-GitHub-Api-Version: 2022-11-28" \
 "https://api.github.com/app/installations/${installation_id}/access_tokens" | jq -r ".token")

git clone https://x-access-token:${installation_token}@github.com/${organization_name}/${target_repository}.git

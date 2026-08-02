#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") [--subscription-id <id>] [--tenant-id <id>] [--resource-group-name <name>] [--identity-name <name>] [--federated-credential-name <name>] [--repository <owner/repo>]

Bootstraps a GitHub Actions user-assigned managed identity (UAMI) for Azure OIDC.
EOF
}

subscription_id="${AZURE_SUBSCRIPTION_ID:-25ce2c45-140d-4d23-b6f6-87bb708d08af}"
tenant_id="${AZURE_TENANT_ID:-3b14ce70-8bea-4d11-9e2c-6b4a04c8010d}"
resource_group_name="${AZURE_RESOURCE_GROUP_NAME:-rg-raininggraces}"
identity_name="${AZURE_IDENTITY_NAME:-id-raininggraces-github-actions}"
federated_credential_name="${AZURE_FEDERATED_CREDENTIAL_NAME:-github-actions-oidc-master}"
repository="${AZURE_REPOSITORY:-x3nc0n/raininggraces}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --subscription-id)
      subscription_id="$2"
      shift 2
      ;;
    --tenant-id)
      tenant_id="$2"
      shift 2
      ;;
    --resource-group-name)
      resource_group_name="$2"
      shift 2
      ;;
    --identity-name)
      identity_name="$2"
      shift 2
      ;;
    --federated-credential-name)
      federated_credential_name="$2"
      shift 2
      ;;
    --repository)
      repository="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$subscription_id" || -z "$tenant_id" || -z "$resource_group_name" || -z "$identity_name" || -z "$federated_credential_name" || -z "$repository" ]]; then
  echo "All parameters are required." >&2
  usage >&2
  exit 1
fi

az_cmd=()
if [[ -x /mnt/c/Windows/System32/cmd.exe ]]; then
  az_cmd=(/mnt/c/Windows/System32/cmd.exe /c az.cmd)
elif [[ "$(uname -s)" == MINGW* ]] || [[ "$(uname -s)" == MSYS* ]]; then
  az_cmd=(cmd.exe /c az.cmd)
elif command -v az.cmd >/dev/null 2>&1; then
  az_cmd=(az.cmd)
elif command -v az >/dev/null 2>&1; then
  az_cmd=(az)
else
  echo "Azure CLI (az) is required but was not found." >&2
  exit 1
fi

"${az_cmd[@]}" account set --subscription "$subscription_id" >/dev/null
if "${az_cmd[@]}" group show --name "$resource_group_name" >/dev/null 2>&1; then
  echo "Using existing resource group '$resource_group_name'."
else
  "${az_cmd[@]}" group create --name "$resource_group_name" --location southcentralus --output none >/dev/null
fi

if "${az_cmd[@]}" identity show --resource-group "$resource_group_name" --name "$identity_name" >/dev/null 2>&1; then
  echo "Using existing managed identity '$identity_name'."
else
  "${az_cmd[@]}" identity create --resource-group "$resource_group_name" --name "$identity_name" --output none >/dev/null
fi

client_id="$("${az_cmd[@]}" identity show --resource-group "$resource_group_name" --name "$identity_name" --query clientId -o tsv)"
principal_id="$("${az_cmd[@]}" identity show --resource-group "$resource_group_name" --name "$identity_name" --query principalId -o tsv)"

scope="/subscriptions/$subscription_id"

role_exists() {
  local role_name="$1"
  local count
  count="$("${az_cmd[@]}" role assignment list --assignee-object-id "$principal_id" --scope "$scope" --query "[?roleDefinitionName=='$role_name'].id | length(@)" -o tsv 2>/dev/null || true)"
  [[ -n "$count" && "$count" != "0" ]]
}

for role_name in "Contributor" "User Access Administrator"; do
  if ! role_exists "$role_name"; then
    "${az_cmd[@]}" role assignment create \
      --assignee-object-id "$principal_id" \
      --assignee-principal-type ServicePrincipal \
      --role "$role_name" \
      --scope "$scope" \
      --output none >/dev/null
  fi
done

issuer="https://token.actions.githubusercontent.com"
subject="repo:${repository}:ref:refs/heads/master"
repository_owner="${repository%%/*}"
audiences="https://github.com/${repository_owner}"

if "${az_cmd[@]}" identity federated-credential show --resource-group "$resource_group_name" --identity-name "$identity_name" --name "$federated_credential_name" >/dev/null 2>&1; then
  "${az_cmd[@]}" identity federated-credential update \
    --resource-group "$resource_group_name" \
    --identity-name "$identity_name" \
    --name "$federated_credential_name" \
    --issuer "$issuer" \
    --subject "$subject" \
    --audiences "$audiences" \
    --output none >/dev/null
else
  "${az_cmd[@]}" identity federated-credential create \
    --resource-group "$resource_group_name" \
    --identity-name "$identity_name" \
    --name "$federated_credential_name" \
    --issuer "$issuer" \
    --subject "$subject" \
    --audiences "$audiences" \
    --output none >/dev/null
fi

echo "GitHub Actions UAMI bootstrap completed."
printf 'clientId=%s\ntenantId=%s\nsubscriptionId=%s\n' "$client_id" "$tenant_id" "$subscription_id"

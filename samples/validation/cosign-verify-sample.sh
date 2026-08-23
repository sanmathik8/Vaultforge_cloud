#!/usr/bin/env bash
# Cosign image signature verification validation asset.
# Usage: ./cosign-verify-sample.sh <IMAGE_DIGEST>
set -euo pipefail

IMAGE_DIGEST="${1:-}"

if [ -z "$IMAGE_DIGEST" ]; then
  echo "Usage: $0 <image-digest-or-ref>"
  exit 1
fi

echo "Verifying image signature for ${IMAGE_DIGEST} via Keyless Cosign OIDC..."

cosign verify "$IMAGE_DIGEST" \
  --certificate-identity-regexp "https://github.com/sanmathik8/Vaultforge_cloud/.*" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com"

echo "Image signature verification successful."

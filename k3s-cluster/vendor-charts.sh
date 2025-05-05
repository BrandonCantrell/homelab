#!/bin/bash

set -euo pipefail

# You are inside 'homelab/k3s-cluster/' when running this
CHARTS_DIR="kube-apps/charts"

# Chart list: chart-name, repo URL, version
CHARTS=(
  "ingress-nginx https://kubernetes.github.io/ingress-nginx 4.12.1"
  "longhorn https://charts.longhorn.io 1.8.1"
  "metallb https://metallb.github.io/metallb 0.14.6"
  "homepage https://jameswynn.github.io/helm-charts 2.0.2"
  "home-assistant http://pajikos.github.io/home-assistant-helm-chart 0.2.117"
  "cert-manager https://charts.jetstack.io 1.13.2 "
  "loki https://grafana.github.io/helm-charts 6.29.0"
  "grafana https://grafana.github.io/helm-charts 6.58.8"
  "prometheus https://prometheus-community.github.io/helm-charts 22.6.7"
  "promtail https://grafana.github.io/helm-charts 6.15.0"
)

# Confirm we are in the right place
if [ ! -d "$CHARTS_DIR" ]; then
  echo "Charts directory $CHARTS_DIR does not exist! Are you in k3s-cluster/ ?"
  exit 1
fi

for ENTRY in "${CHARTS[@]}"; do
  NAME=$(echo "$ENTRY" | awk '{print $1}')
  REPO=$(echo "$ENTRY" | awk '{print $2}')
  VERSION=$(echo "$ENTRY" | awk '{print $3}')

  DEST_DIR="$CHARTS_DIR/$NAME"

  echo "🚀 Checking chart: $NAME from $REPO version $VERSION"

  NEED_PULL=false

  if [ ! -d "$DEST_DIR" ]; then
    echo "Chart $NAME not found locally, will pull."
    NEED_PULL=true
  elif [ -f "$DEST_DIR/Chart.yaml" ]; then
    LOCAL_VERSION=$(grep '^version:' "$DEST_DIR/Chart.yaml" | sed 's/version:[[:space:]]*//')
    if [ "$LOCAL_VERSION" != "$VERSION" ]; then
      echo "Version mismatch for $NAME (local: $LOCAL_VERSION, desired: $VERSION), will re-pull."
      NEED_PULL=true
    else
      echo "Chart $NAME is already correct version ($VERSION). Skipping."
    fi
  else
    echo " Chart.yaml missing for $NAME, will pull fresh."
    NEED_PULL=true
  fi

  if [ "$NEED_PULL" = true ]; then
    # Remove old chart if it exists
    rm -rf "$DEST_DIR"

    # Pull and untar the chart
    helm pull "$NAME" --repo "$REPO" --version "$VERSION" --untar --untardir "$CHARTS_DIR"

    # Remove any .tgz file if present
    rm -rf "$CHARTS_DIR/$NAME"-*.tgz

    echo "Pulled and updated $NAME."
  fi
done

echo "All charts are up to date!"

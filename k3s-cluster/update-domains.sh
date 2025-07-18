#!/bin/bash

set -euo pipefail

echo "🚀 Updating all .homelab domains to .opsguy.io domains..."

# Array of files to update with their old->new domain mappings
declare -A FILES_TO_UPDATE=(
    # Helm values files
    ["kube-apps/values/longhorn-values.yaml"]="longhorn.homelab->longhorn.opsguy.io home.homelab->home.opsguy.io"
    ["kube-apps/values/homepage-values.yaml"]="home.homelab->home.opsguy.io"
    ["kube-apps/values/homeassistant-values.yaml"]="homeassistant.homelab->homeassistant.opsguy.io"
    ["kube-apps/values/prometheus-values.yaml"]="alertmanager.homelab->alertmanager.opsguy.io prometheus.homelab->prometheus.opsguy.io"
    ["kube-apps/values/grafana-values.yaml"]="grafana.homelab->grafana.opsguy.io"
    ["kube-apps/charts/stash/values.yaml"]="stash.homelab->stash.opsguy.io"
    
    # Manifest files
    ["kube-apps/manifests/homebridge/ingress.yaml"]="homebridge.homelab->homebridge.opsguy.io"
    
    # Homepage config (both ingress and external links)
    ["kube-apps/manifests/homepage/configmap.yaml"]="longhorn.homelab->longhorn.opsguy.io grafana.homelab->grafana.opsguy.io prometheus.homelab->prometheus.opsguy.io wled-tree.homelab->wled-tree.opsguy.io homeassistant.homelab->homeassistant.opsguy.io octoprint.homelab->octoprint.opsguy.io homebridge.homelab->homebridge.opsguy.io"
)

# Function to update domains in a file
update_file() {
    local file="$1"
    local mappings="$2"
    
    if [ ! -f "$file" ]; then
        echo "⚠️  Warning: File $file not found, skipping..."
        return
    fi
    
    echo "📝 Updating $file..."
    
    # Create backup
    cp "$file" "$file.backup"
    
    # Apply each mapping
    for mapping in $mappings; do
        old_domain=$(echo "$mapping" | cut -d'-' -f1)
        new_domain=$(echo "$mapping" | cut -d'>' -f2)
        
        echo "   $old_domain -> $new_domain"
        sed -i.tmp "s/$old_domain/$new_domain/g" "$file"
        rm -f "$file.tmp"
    done
}

# Update all files
for file in "${!FILES_TO_UPDATE[@]}"; do
    update_file "$file" "${FILES_TO_UPDATE[$file]}"
done

echo ""
echo "✅ Domain updates complete!"
echo ""
echo "📋 Summary of changes:"
echo "   longhorn.homelab -> longhorn.opsguy.io"
echo "   home.homelab -> home.opsguy.io"
echo "   homeassistant.homelab -> homeassistant.opsguy.io"
echo "   alertmanager.homelab -> alertmanager.opsguy.io"
echo "   homebridge.homelab -> homebridge.opsguy.io"
echo "   stash.homelab -> stash.opsguy.io"
echo "   grafana.homelab -> grafana.opsguy.io"
echo "   prometheus.homelab -> prometheus.opsguy.io"
echo "   wled-tree.homelab -> wled-tree.opsguy.io"
echo "   octoprint.homelab -> octoprint.opsguy.io"
echo ""
echo "📦 Next steps:"
echo "1. Review the changes: git diff"
echo "2. Update DNS to point *.opsguy.io to your cluster IP"
echo "3. Apply cert-manager changes: kubectl apply -f kube-apps/manifests/cert-manager-config/"
echo "4. Restart ApplicationSets to pick up new configs"
echo ""
echo "💾 Backup files created with .backup extension"
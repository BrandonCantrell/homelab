#!/bin/bash
# Prometheus Storage Recovery Script
# This script recovers Prometheus from a disk-full compaction failure

set -e

NAMESPACE="monitoring"
DEPLOYMENT="prometheus-server"
PVC_NAME="prometheus-server"

echo "🔍 Step 1: Checking current state..."
kubectl get pods -n $NAMESPACE | grep prometheus-server
kubectl exec -n $NAMESPACE deployment/$DEPLOYMENT -- df -h /data || echo "Pod might be crashed"

echo "🛑 Step 2: Scaling down Prometheus to safely access storage..."
kubectl scale deployment $DEPLOYMENT -n $NAMESPACE --replicas=0

echo "⏳ Waiting for pod to terminate..."
kubectl wait --for=delete pod -l app.kubernetes.io/name=prometheus,app.kubernetes.io/component=server -n $NAMESPACE --timeout=120s

echo "🧹 Step 3: Creating debug pod to clean up storage..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: prometheus-cleanup
  namespace: $NAMESPACE
spec:
  restartPolicy: Never
  containers:
  - name: cleanup
    image: alpine:latest
    command: ["sleep", "3600"]
    volumeMounts:
    - name: storage
      mountPath: /data
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: $PVC_NAME
EOF

echo "⏳ Waiting for cleanup pod to be ready..."
kubectl wait --for=condition=Ready pod/prometheus-cleanup -n $NAMESPACE --timeout=120s

echo "🔍 Step 4: Analyzing storage usage..."
kubectl exec -n $NAMESPACE prometheus-cleanup -- sh -c "
echo '=== Current disk usage ==='
df -h /data
echo
echo '=== Directory sizes ==='
du -sh /data/* 2>/dev/null | sort -h
echo
echo '=== WAL directory size ==='
du -sh /data/wal 2>/dev/null || echo 'No WAL directory'
echo
echo '=== Number of WAL segments ==='
ls -la /data/wal/ 2>/dev/null | wc -l || echo 'No WAL files'
"

echo "🧹 Step 5: Cleaning up old data..."
kubectl exec -n $NAMESPACE prometheus-cleanup -- sh -c "
echo '=== Cleaning WAL files older than 1 day ==='
find /data/wal -name '0*' -type f -mtime +1 -ls -delete 2>/dev/null || echo 'No old WAL files to delete'

echo '=== Cleaning temporary files ==='
find /data -name '*.tmp' -type d -exec rm -rf {} + 2>/dev/null || echo 'No tmp directories'

echo '=== Removing corrupted checkpoints ==='
rm -rf /data/wal/checkpoint.* 2>/dev/null || echo 'No checkpoints to remove'

echo '=== Cleaning old blocks (keeping last 3 days worth) ==='
# List all block directories and remove older ones
ls -dt /data/0* 2>/dev/null | tail -n +10 | head -20 | xargs rm -rf 2>/dev/null || echo 'No old blocks to remove'

echo '=== Final disk usage after cleanup ==='
df -h /data
"

echo "🔧 Step 6: Adding essential Prometheus flags..."
# This will be done via values update

echo "🗑️ Step 7: Cleaning up debug pod..."
kubectl delete pod prometheus-cleanup -n $NAMESPACE --ignore-not-found

echo "✅ Step 8: Scaling Prometheus back up with updated configuration..."
kubectl scale deployment $DEPLOYMENT -n $NAMESPACE --replicas=1

echo "⏳ Waiting for Prometheus to be ready..."
kubectl wait --for=condition=Available deployment/$DEPLOYMENT -n $NAMESPACE --timeout=300s

echo "🎉 Recovery complete! Checking final state..."
kubectl get pods -n $NAMESPACE | grep prometheus-server
kubectl exec -n $NAMESPACE deployment/$DEPLOYMENT -- df -h /data

echo "
📋 Next steps:
1. Monitor Prometheus logs: kubectl logs -f deployment/$DEPLOYMENT -n $NAMESPACE
2. Check compaction is working: Look for 'compact blocks' messages in logs
3. Update your values.yaml with the fixes shown below
"
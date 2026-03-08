# EFS Sharing for Multiple Nominatim Instances

## Overview
This Helm chart supports deploying multiple Nominatim instances (different regions) that share the same AWS EFS filesystem **safely** without data collision.

## How It Works

### SubPath Isolation
Each Nominatim region writes to **isolated subdirectories** on the shared EFS filesystem:

- **South Africa**: `za/postgresql` and `za/flatnode`
- **Israel**: `il/postgresql` and `il/flatnode`

The chart automatically generates these subPaths based on the `regionConfig.countryCode` field.

### Storage Architecture

```
EFS Filesystem (e.g., fs-095d06d9ab85e1858)
├── za/
│   ├── postgresql/     ← South Africa PostgreSQL data
│   └── flatnode/       ← South Africa flatnode files
└── il/
    ├── postgresql/     ← Israel PostgreSQL data
    └── flatnode/       ← Israel flatnode files
```

### Template Logic

From `templates/_helpers.tpl`:

```go
{{- define "nominatim.postgresqlSubPath" -}}
{{- $rc := (include "nominatim.effectiveRegionConfig" . | fromYaml) -}}
{{- printf "%s/postgresql" $rc.countryCode }}
{{- end }}

{{- define "nominatim.flatnodeSubPath" -}}
{{- $rc := (include "nominatim.effectiveRegionConfig" . | fromYaml) -}}
{{- printf "%s/flatnode" $rc.countryCode }}
{{- end }}
```

## Why This Is Safe

### ✅ Data Isolation
- Each region has a unique `countryCode` (e.g., `za`, `il`)
- SubPaths ensure complete directory separation
- No possibility of data overwrite between regions

### ✅ Resource Isolation
- Each deployment creates unique PV names: `nominatim-{release}-{region}-efs-pv`
- Each deployment creates unique PVC names: `nominatim-{release}-{region}-efs-claim`
- Each deployment creates unique StatefulSet names: `nominatim-{release}-{region}-statefulset`

### ✅ StorageClass Management
- First deployment creates the `efs-sc` StorageClass
- Subsequent deployments set `storage.createStorageClass: false` to reuse it
- Prevents "resource already exists" conflicts in ArgoCD

## Example Configurations

### First Deployment (South Africa - Prod)
```yaml
# argocd/clusters/prod-1/nominatim/nominatim.yaml
helm:
  valuesObject:
    # Uses default nominatimRegion: south-africa
    storage:
      enabled: true
      efsVolumeHandle: "fs-095d06d9ab85e1858"
      # createStorageClass: true (default)
```

Result: Creates `za/postgresql` and `za/flatnode` directories

### Second Deployment (Israel - Prod)
```yaml
# argocd/clusters/prod-1/nominatim/nominatim-israel.yaml
helm:
  valuesObject:
    nominatimRegion: "israel"
    storage:
      enabled: true
      createStorageClass: false  # ← Reuse existing StorageClass
      efsVolumeHandle: "fs-095d06d9ab85e1858"  # ← Same EFS
```

Result: Creates `il/postgresql` and `il/flatnode` directories on the same EFS

## Important Notes

### ⚠️ StorageClass Ownership
Only the **first** deployment should create the StorageClass. All subsequent deployments sharing the same EFS must set:
```yaml
storage:
  createStorageClass: false
```

### ⚠️ Different EFS Per Environment
While multiple regions can share one EFS within an environment, **different environments** (dev, prod) should use **different EFS filesystems**:

- **Dev**: `fs-0006b32a91f2d27c4`
- **Prod-1**: `fs-095d06d9ab85e1858`

### ⚠️ Performance Considerations
- Multiple instances share EFS I/O throughput
- Heavy concurrent imports may impact performance
- Consider using **EFS Access Points** for production-grade isolation

## Best Practice: EFS Access Points (Optional)

For enhanced security and isolation, use EFS Access Points:

```yaml
# Example with Access Point
storage:
  efsVolumeHandle: "fs-095d06d9ab85e1858::fsap-0123456789abcdef0"
```

This provides:
- Enforced root directory per region
- UID/GID enforcement
- Better security boundaries

## Validation

To verify subPath isolation, render the templates:

```bash
# South Africa (default)
helm template nominatim ./charts/nominatim \
  --set storage.enabled=true \
  --set storage.efsVolumeHandle="fs-095d06d9ab85e1858" \
  | grep subPath

# Israel
helm template nominatim-israel ./charts/nominatim \
  --set nominatimRegion=israel \
  --set storage.enabled=true \
  --set storage.efsVolumeHandle="fs-095d06d9ab85e1858" \
  | grep subPath
```

Expected output:
- South Africa: `subPath: za/postgresql` and `subPath: za/flatnode`
- Israel: `subPath: il/postgresql` and `subPath: il/flatnode`

## Troubleshooting

### Issue: "StorageClass already exists"
**Solution**: Set `storage.createStorageClass: false` in the second deployment

### Issue: Data appears to be shared between regions
**Cause**: Both regions using the same `countryCode`
**Solution**: Verify `nominatimRegion` is set correctly (e.g., `israel` vs `south-africa`)

### Issue: Permission denied on mount
**Cause**: EFS directories don't exist or have wrong permissions
**Solution**: Pre-create directories or use EFS Access Points with proper UID/GID

## Summary

✅ **Safe to share EFS** between multiple Nominatim regions  
✅ **SubPath isolation** prevents data collision  
✅ **Unique resource names** prevent Kubernetes conflicts  
✅ **StorageClass reuse** prevents ArgoCD sync issues  

The chart is designed to make multi-region deployment safe and straightforward.

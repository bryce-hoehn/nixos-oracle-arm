# nixos-oracle-arm

NixOS QCOW2 image builder for Oracle Cloud ARM64 (Ampere) instances.

## GitHub Actions Workflows

### Upload to OCI + Import Image

The [`upload-to-oci.yml`](.github/workflows/upload-to-oci.yml) workflow is triggered on release publication (or manually via `workflow_dispatch`). It:

1. Downloads the QCOW2 image from the latest GitHub release (supports both `.zip` and `.tar.gz` archives)
2. Uploads it to an Oracle Cloud Object Storage bucket via the S3-compatible API
3. **(Optional)** Automatically imports the image as a custom compute image in OCI
4. **(Optional)** Cleans up old images and bucket objects

The image import step is **opt-in** — it only runs if you configure the `OCI_COMPARTMENT_OCID` secret. Without it, the workflow stops after the S3 upload.

### Deploy NixOS Instance

The [`deploy-instance.yml`](.github/workflows/deploy-instance.yml) workflow is manually triggered (`workflow_dispatch`) and deploys the latest imported image as a `VM.Standard.A1.Flex` instance using Terraform.

**Workflow inputs:**

| Input | Description | Default |
|-------|-------------|---------|
| `instance_name` | Display name for the instance | *(required)* |
| `availability_domain` | AD to place the instance in (e.g. `zXrW:US-ASHBURN-AD-1`) | *(required)* |
| `ocpus` | Number of OCPUs (1–4) | `2` |
| `memory_in_gbs` | RAM in GB (1–24) | `12` |
| `boot_volume_size_in_gbs` | Boot volume size in GB | `50` |
| `ssh_public_key` | SSH public key for the instance | *(required)* |
| `create_network` | Create a new VCN + public subnet | `true` |
| `subnet_ocid` | Existing subnet OCID (when `create_network` is false) | *(optional)* |
| `image_ocid` | Custom image OCID (leave blank to auto-detect latest) | *(optional)* |
| `max_retries` | Max provisioning attempts (A1 capacity is limited) | `100` |
| `retry_delay_seconds` | Seconds between retries | `120` |

The workflow stores Terraform state in OCI Object Storage via the S3-compatible API, so state persists between runs. Re-running with different parameters (e.g. a new image) will update the existing resources in place.

**Capacity retry:** Oracle Cloud frequently runs out of A1.Flex capacity. The workflow automatically retries `terraform apply` on failure (up to `max_retries` times, waiting `retry_delay_seconds` between attempts). The job timeout is set to 6 hours. If retries are exhausted, simply re-run the workflow.

**Finding your availability domain:**

```bash
oci iam availability-domain list --compartment-id <compartment-ocid>
```

## Required Secrets

### S3 Upload (always required)

| Secret | Description |
|--------|-------------|
| `OCI_S3_ACCESS_KEY` | Access key for the OCI S3-compatible API |
| `OCI_S3_SECRET_KEY` | Secret key for the OCI S3-compatible API |
| `OCI_S3_REGION` | OCI region (e.g. `us-ashburn-1`) |
| `OCI_S3_ENDPOINT` | S3-compatible endpoint URL (e.g. `https://<namespace>.compat.objectstorage.<region>.oci.oraclecloud.com`) |
| `OCI_S3_BUCKET` | Object Storage bucket name |
| `OCI_S3_DEST_PREFIX` | (Optional) Key prefix for uploaded objects |

### OCI API (required for image import and instance deployment)

| Secret | Description |
|--------|-------------|
| `OCI_COMPARTMENT_OCID` | OCID of the compartment (**setting this enables the import step**) |
| `OCI_TENANCY_OCID` | OCID of your OCI tenancy |
| `OCI_USER_OCID` | OCID of the OCI user with compute image import permissions |
| `OCI_API_KEY_PRIVATE` | PEM-formatted RSA private key for OCI API authentication |
| `OCI_API_KEY_FINGERPRINT` | Fingerprint of the API key (e.g. `aa:bb:cc:...`) |

### Setting up OCI API authentication

1. Generate an RSA key pair:
   ```bash
   openssl genrsa -out oci_api_key.pem 2048
   openssl rsa -in oci_api_key.pem -pubout -out oci_api_key_public.pem
   ```
2. Upload the public key to your OCI user profile (Identity → Users → API Keys)
3. Note the **fingerprint** shown after uploading
4. Store the private key PEM content as the `OCI_API_KEY_PRIVATE` secret

### Required IAM policy

The OCI user needs the following permissions (adjust scope as needed):

```
Allow group <your-group> to manage compute-images in compartment <your-compartment>
Allow group <your-group> to read objectstorage-namespaces in tenancy
Allow group <your-group> to manage buckets in compartment <your-compartment>
Allow group <your-group> to manage objects in compartment <your-compartment>
Allow group <your-group> to manage virtual-network-family in compartment <your-compartment>
Allow group <your-group> to manage instance-family in compartment <your-compartment>
Allow group <your-group> to manage volume-family in compartment <your-compartment>
```

## Project Structure

```
├── .github/workflows/
│   ├── upload-to-oci.yml         # Upload → import → cleanup pipeline
│   └── deploy-instance.yml       # Terraform deploy workflow
├── terraform/
│   └── main.tf                   # OCI instance Terraform config
├── nixos/
│   └── configuration.nix         # NixOS configuration
└── flake.nix                     # Nix flake for building the QCOW2 image
```

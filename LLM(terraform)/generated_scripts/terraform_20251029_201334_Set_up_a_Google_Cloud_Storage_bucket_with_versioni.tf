```terraform
resource "google_storage_bucket" "versioned_bucket" {
  name          = "my-versioned-gcs-bucket-12345" # Replace with a globally unique name
  location      = "US-CENTRAL1"
  project       = "your-gcp-project-id" # Replace with your GCP project ID

  versioning {
    enabled = true
  }

  uniform_bucket_level_access = true
  force_destroy                = false
}
```
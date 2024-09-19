# Переменные для YC и провайдер
variable "yc_token" {
  default = "t1.9euelZrNnp3MlpfLjpyYjY6VkJaei-3rnpWakJLLj8mdxpmUisqelpqZmpfl8_cUO1BI-e8GKFUX_d3z91RpTUj57wYoVRf9zef1656VmpmSjImWyZmbl8fOmMuVlZWV7_zF656VmpmSjImWyZmbl8fOmMuVlZWV.-Drt_AwjLX55VcI2v7SH3OIS5u_5uYZq1G_XswH1u0tQshiLZMWt32pKXRE1yWgFvPtYpHDh0cCeQ8Vgz3>
  }
variable "yc_cloud_id" {
  default = "b1g9422l5eafjv34bjtu"
  }
variable "yc_folder_id" {
  default = "b1gosv5aehv25rrbjfq4"
  }
variable "yc_zone" {
  default = "ru-central1-a"
  }

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone = var.yc_zone
}

# Ключ шифрования и бакет

resource "yandex_iam_service_account" "sa-bucket" {
  name        = "sa-bucket"
}
resource "yandex_resourcemanager_folder_iam_member" "roleassignment-storageeditor" {
  folder_id = var.yc_folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa-bucket.id}"
}
resource "yandex_iam_service_account_static_access_key" "accesskey-bucket" {
  service_account_id = yandex_iam_service_account.sa-bucket.id
}
resource "yandex_kms_symmetric_key" "encryptkey" {
  name              = "encryptkey"
}

resource "yandex_storage_bucket" "schukin-190924" {
  access_key = yandex_iam_service_account_static_access_key.accesskey-bucket.access_key
  secret_key = yandex_iam_service_account_static_access_key.accesskey-bucket.secret_key
  bucket     = "schukin-190924"
  default_storage_class = "STANDARD"
  acl           = "public-read"
  force_destroy = "true"
  anonymous_access_flags {
    read = true
    list = true
    config_read = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.encryptkey.id
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "yandex_storage_object" "cat" {
  access_key = yandex_iam_service_account_static_access_key.accesskey-bucket.access_key
  secret_key = yandex_iam_service_account_static_access_key.accesskey-bucket.secret_key
  bucket     = yandex_storage_bucket.schukin-190924.id
  key        = "cat.png"
  source     = "cat.png"
}

# VPC
resource "yandex_vpc_network" "network-netology" {
  name = "network-netology"
}

output "picture_url" {
  value = "https://${yandex_storage_bucket.schukin-190924.bucket_domain_name}/${yandex_storage_object.cat.key}"
}

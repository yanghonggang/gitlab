---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# GitLab Package Registry administration

GitLab Packages allows organizations to utilize GitLab as a private repository
for a variety of common package managers. Users are able to build and publish
packages, which can be easily consumed as a dependency in downstream projects.

The Packages feature allows GitLab to act as a repository for the following:

| Software repository | Description | Available in GitLab version |
| ------------------- | ----------- | --------------------------- |
| [PyPI Repository](../../user/packages/pypi_repository/index.md) | The GitLab PyPI Repository enables every project in GitLab to have its own space to store [PyPI](https://pypi.org/) packages. | 12.10+ |
| [Composer Repository](../../user/packages/composer_repository/index.md) | The GitLab Composer Repository enables every project in GitLab to have its own space to store [Composer](https://getcomposer.org/) packages. | 13.1+ |
| [NuGet Repository](../../user/packages/nuget_repository/index.md) | The GitLab NuGet Repository enables every project in GitLab to have its own space to store [NuGet](https://www.nuget.org/) packages. | 12.8+ |
| [Conan Repository](../../user/packages/conan_repository/index.md) | The GitLab Conan Repository enables every project in GitLab to have its own space to store [Conan](https://conan.io/) packages. | 12.4+ |
| [Maven Repository](../../user/packages/maven_repository/index.md) | The GitLab Maven Repository enables every project in GitLab to have its own space to store [Maven](https://maven.apache.org/) packages. | 11.3+ |
| [NPM Registry](../../user/packages/npm_registry/index.md)   | The GitLab NPM Registry enables every project in GitLab to have its own space to store [NPM](https://www.npmjs.com/) packages. | 11.7+ |
| [Go Proxy](../../user/packages/go_proxy/index.md) | The Go proxy for GitLab enables every project in GitLab to be fetched with the [Go proxy protocol](https://proxy.golang.org/). | 13.1+ |
| [Generic packages](../../user/packages/generic_packages/index.md) | Store arbitrary files, like release binaries. | 13.5+ |

Don't you see your package management system supported yet?
Please consider contributing
to GitLab. This [development documentation](../../development/packages.md) will guide you through the process.

## Enabling the Packages feature

NOTE: **Note:**
After the Packages feature is enabled, the repositories are available
for all new projects by default. To enable it for existing projects, users will
have to explicitly do so in the project's settings.

To enable the Packages feature:

**Omnibus GitLab installations**

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['packages_enabled'] = true
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure "How to reconfigure Omnibus GitLab") for the changes to take effect.

**Installations from source**

1. After the installation is complete, you will have to configure the `packages`
   section in `config/gitlab.yml`. Set to `true` to enable it:

   ```yaml
   packages:
     enabled: true
   ```

1. [Restart GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure "How to reconfigure Omnibus GitLab") for the changes to take effect.

## Changing the storage path

By default, the packages are stored locally, but you can change the default
local location or even use object storage.

### Changing the local storage path

The packages for Omnibus GitLab installations are stored under
`/var/opt/gitlab/gitlab-rails/shared/packages/` and for source
installations under `shared/packages/` (relative to the Git home directory).
To change the local storage path:

**Omnibus GitLab installations**

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['packages_storage_path'] = "/mnt/packages"
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure)
   for the changes to take effect.

**Installations from source**

1. Edit the `packages` section in `config/gitlab.yml`:

   ```yaml
   packages:
     enabled: true
     storage_path: shared/packages
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#installations-from-source) for the changes to take effect.

### Using object storage

Instead of relying on the local storage, you can use an object storage to
store packages.

[Read more about using object storage with GitLab](../object_storage.md).

NOTE: **Note:**
We recommend using the [consolidated object storage settings](../object_storage.md#consolidated-object-storage-configuration). The following instructions apply to the original config format.

**Omnibus GitLab installations**

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines (uncomment where
   necessary):

   ```ruby
   gitlab_rails['packages_enabled'] = true
   gitlab_rails['packages_object_store_enabled'] = true
   gitlab_rails['packages_object_store_remote_directory'] = "packages" # The bucket name.
   gitlab_rails['packages_object_store_direct_upload'] = false         # Use Object Storage directly for uploads instead of background uploads if enabled (Default: false).
   gitlab_rails['packages_object_store_background_upload'] = true      # Temporary option to limit automatic upload (Default: true).
   gitlab_rails['packages_object_store_proxy_download'] = false        # Passthrough all downloads via GitLab instead of using Redirects to Object Storage.
   gitlab_rails['packages_object_store_connection'] = {
     ##
     ## If the provider is AWS S3, uncomment the following
     ##
     #'provider' => 'AWS',
     #'region' => 'eu-west-1',
     #'aws_access_key_id' => 'AWS_ACCESS_KEY_ID',
     #'aws_secret_access_key' => 'AWS_SECRET_ACCESS_KEY',
     ## If an IAM profile is being used with AWS, omit the aws_access_key_id and aws_secret_access_key and uncomment
     #'use_iam_profile' => true,
     ##
     ## If the provider is other than AWS (an S3-compatible one), uncomment the following
     ##
     #'host' => 's3.amazonaws.com',
     #'aws_signature_version' => 4             # For creation of signed URLs. Set to 2 if provider does not support v4.
     #'endpoint' => 'https://s3.amazonaws.com' # Useful for S3-compliant services such as DigitalOcean Spaces.
     #'path_style' => false                    # If true, use 'host/bucket_name/object' instead of 'bucket_name.host/object'.
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure)
   for the changes to take effect.

**Installations from source**

1. Edit the `packages` section in `config/gitlab.yml` (uncomment where necessary):

   ```yaml
   packages:
     enabled: true
     ##
     ## The location where build packages are stored (default: shared/packages).
     ##
     # storage_path: shared/packages
     object_store:
       enabled: false
       remote_directory: packages  # The bucket name.
       # direct_upload: false      # Use Object Storage directly for uploads instead of background uploads if enabled (Default: false).
       # background_upload: true   # Temporary option to limit automatic upload (Default: true).
       # proxy_download: false     # Passthrough all downloads via GitLab instead of using Redirects to Object Storage.
       connection:
       ##
       ## If the provider is AWS S3, use the following:
       ##
         provider: AWS
         region: us-east-1
         aws_access_key_id: AWS_ACCESS_KEY_ID
         aws_secret_access_key: AWS_SECRET_ACCESS_KEY
         ##
         ## If the provider is other than AWS (an S3-compatible one), comment out the previous 4 lines and use the following instead:
         ##
         #  host: 's3.amazonaws.com'             # default: s3.amazonaws.com.
         #  aws_signature_version: 4             # For creation of signed URLs. Set to 2 if provider does not support v4.
         #  endpoint: 'https://s3.amazonaws.com' # Useful for S3-compliant services such as DigitalOcean Spaces.
         #  path_style: false                    # If true, use 'host/bucket_name/object' instead of 'bucket_name.host/object'.
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#installations-from-source) for the changes to take effect.

### Migrating local packages to object storage

After [configuring the object storage](#using-object-storage), you may use the
following task to migrate existing packages from the local storage to the remote one.
The processing will be done in a background worker and requires **no downtime**.

For Omnibus GitLab:

```shell
sudo gitlab-rake "gitlab:packages:migrate"
```

For installations from source:

```shell
RAILS_ENV=production sudo -u git -H bundle exec rake gitlab:packages:migrate
```

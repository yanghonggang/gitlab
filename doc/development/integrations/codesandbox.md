# Set up local Codesandbox development environment

This guide walks through setting up a local [Codesandbox repository](https://github.com/codesandbox/codesandbox-client) and integrating it with a local GitLab instance. Codesandbox 
is used to power the Web IDE's [Live Preview feature](../../user/project/web_ide/index.md#live-preview). Having a local Codesandbox setup is useful for debugging upstream issues or 
creating upstream contributions like [this one](https://github.com/codesandbox/codesandbox-client/pull/5137).

## One-time Setup

### 1 - Setup GDK with HTTPS

Codesandbox uses Service Workers which require `https`, so make sure you have your local GDK running using the `https` setup.

Follow the [GDK NGINX configuration instructions](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/master/doc/howto/nginx.md) for how to run GDK locally with HTTPS.

### 2 - Clone Codesandbox project

Clone the [`codesandbox-client` project](https://github.com/codesandbox/codesandbox-client) locally. If you plan on contributing upstream, you might want to fork and clone first.

### 2.a - (Optional) Setup `asdf` environment dependencies

In the `codesandbox-client` project directory,

```shell
# If you're using asdf, this might be necessary
asdf local nodejs 10.14.2
asdf local python 2.7.18
```

### 3 - Initial build

```shell
# This might be necessary for the `prepublishOnly` job which is run later
yarn global add lerna

# Install packages
yarn
```

You can run `yarn build:clean` to clean up the build assets.

## Running local GitLab with local Codesandbox

GitLab has two pieces of Codesandbox it integrates with:

1. A npm package called `smooshpack` (called `sandpack` in the `codesandbox-client` project). This exposes an entrypoint for us to kick off Codesandbox's bundler.
1. A server that houses Codesandbox assets for bundling and previewing. This is hosted on a separate server for security.

### 1 - Link and Build Codesandbox `smooshpack` package

In the `codesandbox-client` project directory:

```shell
cd standalone-packages/sandpack

yarn link

# (Optional) you might want to start a development build
yarn run start
```

Now, when you're in the GitLab project, you can run `yarn link "smooshpack"`. This way `yarn` will look 
for `smooshpack` **on disk** as opposed to the one in the package manager.

### 2 - Link local GitLab to local `smooshpack` package

In the GitLab project directory:

```shell
# Remove and reinstall node_modules just to be safe
rm -rf node_modules
yarn

# Use the "smooshpack" package **on disk**
yarn link "smooshpack"
```

### 2.a (Optional) - Fix GDK webpack from breaking with linked package

It appears that the GDK `webpack` has a hard time finding packages once it's inside the linked package. If you skip this step, you might run into `webpack` breaking with messages saying that it can't resolve packages from `smooshpack/dist/sandpack.es5.js`.

In the `codesandbox-client` project directory:

```shell
cd standalone-packages

mkdir node_modules
ln -s $PATH_TO_LOCAL_GITLAB/node_modules/core-js ./node_modules/core-js
```

### 3 - Start building codesandbox app assets

In the `codesandbox-client` project directory:

```shell
cd packages/app

yarn start:sandpack-sandbox
```

### 4 - Create HTTPS proxy for Codesandbox `sandpack` assets

Since we need `https` we need to create a proxy to the webpack server. There's a very helpful `npm` package [called `http-server`](https://www.npmjs.com/package/http-server), which can do this proxying out of the box.

```shell
npx http-server --proxy http://localhost:3000 -S -C $PATH_TO_CERT_PEM -K $PATH_TO_KEY_PEM -p 8044 -d false
```

### 5 - Update `bundler_url` setting in GitLab

We need to update our `application_setting_implementation.rb` to point to the server hosting the 
Codesandbox `sandpack` assets. For instance, if these assets are hosted by a server at `https://sandpack.local:8044`:

```patch
diff --git a/app/models/application_setting_implementation.rb b/app/models/application_setting_implementation.rb
index 6eed627b502..1824669e881 100644
--- a/app/models/application_setting_implementation.rb
+++ b/app/models/application_setting_implementation.rb
@@ -391,7 +391,7 @@ def static_objects_external_storage_enabled?
   # This will eventually be configurable
   # https://gitlab.com/gitlab-org/gitlab/issues/208161
   def web_ide_clientside_preview_bundler_url
-    'https://sandbox-prod.gitlab-static.net'
+    'https://sandpack.local:8044'
   end
 
   private

```

<small>You can apply this patch by copying it to your clipboard and running `pbpaste | git apply`.</small>

You'll probably want to restart the GitLab Rails server after making this change.

# travis-utils

A collection of scripts we use on [Travis](https://travis-ci.org).

## chrome.sh

Installs [Google Chrome](https://www.google.com/chrome/), including a custom build of `chrome-sandbox` binary that [works in OpenVZ containers](https://code.google.com/p/chromium/issues/detail?id=412698).  It defaults to the current stable release, which you can override with the `CHROME_VERSION` environment variable.  Use it in your `before_script` section:

```yaml
before_script:
  - "curl -sSL https://github.com/goodeggs/travis-utils/raw/master/chrome.sh | sh"
```

## chromedriver.sh

Installs and starts a blessed version of [Chromedriver](https://code.google.com/p/selenium/wiki/ChromeDriver).  You may override our version with the `CHROMEDRIVER_VERSION` environment variable.  Also exports the correct `DISPLAY` environment variable and starts `xvfb` for you.  Use it in your `before_script` section:

```yaml
before_script:
  - "curl -sSL https://github.com/goodeggs/travis-utils/raw/master/chromedriver.sh | sh"
```

## npm-install.sh

Glorified `npm install` that handles the presence of a cached `node_modules` directory (pruning, rebuilding if node version changed).  Use it as your `install` command for node-based projects:

```yaml
install: "curl -sSL https://github.com/goodeggs/travis-utils/raw/master/npm-install.sh | sh"
```

## mongodb.sh

Installs MongoDB from their official APT repo.  You may specify the APT package version with the `MONGO_VERSION` environment variable.  Use it in your `before_script` section:

```yaml
before_script:
  - "curl -sSL https://github.com/goodeggs/travis-utils/raw/master/mongodb.sh | sh"
```


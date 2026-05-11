# Homebrew distribution

This directory holds the draft Homebrew formula for the `swiftumlbridge`
CLI. It is **not** a working Homebrew tap — Homebrew expects formulae to
live in a repository named `homebrew-<tap>` at the root or in a
`Formula/` directory.

## Recommended distribution path

Create a separate tap repository, e.g. `Joseph-Cursio/homebrew-tap`,
copy `Formula/swiftumlbridge.rb` into its root or `Formula/`, then:

```bash
brew tap Joseph-Cursio/tap
brew install swiftumlbridge
```

Alternatively, install directly from the local file for ad-hoc use:

```bash
brew install --build-from-source ./homebrew/Formula/swiftumlbridge.rb
```

## Updating for new releases

1. Tag a new release and publish it through GitHub (see `gh release create`).
2. Fetch the tarball and compute its SHA256:

   ```bash
   curl -sL https://github.com/Joseph-Cursio/SwiftUMLStudio/archive/refs/tags/vX.Y.Z.tar.gz \
     | shasum -a 256
   ```

3. Bump the `url`, `sha256`, and `test do` version assertion in
   `Formula/swiftumlbridge.rb`. Bump the `Version.current` constant in
   the framework *before* tagging so the CLI's `--version` flag matches
   the formula's assertion.

# tofi for Void Linux (x86_64-musl / Intel Skylake)

A hardware-specific Void Linux XBPS package for [tofi](https://github.com/philj56/tofi), targeting **x86_64-musl** and Intel Skylake CPUs, with the Intel Core i3-6100U as the reference processor.

This repository packages upstream tofi; it does not fork or modify the application source.

## Target and compatibility

- Distribution: Void Linux
- XBPS target: `x86_64-musl` only
- CPU target: Intel Skylake (`-march=skylake -mtune=skylake`)
- Reference CPU: Intel Core i3-6100U
- Build system: Meson / Ninja
- C library: musl

This is not a generic x86_64 binary. The Skylake compiler target can emit instructions unsupported by older x86_64 processors. It is not intended for pre-Skylake CPUs, glibc systems, or non-x86_64 architectures.

GitHub Actions builds the package on a hosted runner. The runner is only the build host; the XBPS target ABI and compiler flags select the device architecture. Compilation does not need to run on the i3-6100U itself.

## Package details

The package recipe follows Void Linux's `srcpkgs/tofi/template`:

- Upstream version: **0.9.1**
- XBPS revision: **1**
- Build style: Meson
- License: MIT
- Upstream source archive is pinned by SHA-256 and verified by `xbps-src`.
- musl builds add `musl-fts-devel` and link with `-lfts`.

Void's downstream `fix-32bit-tests.patch` is not carried here: it addresses 32-bit parsing tests, while this repository deliberately builds only `x86_64-musl`.

## Build locally

On a Void Linux host, install the tools needed to run `xbps-src`, then:

```sh
git clone https://github.com/rmicro/tofi.git
git clone https://github.com/void-linux/void-packages.git

rm -rf void-packages/srcpkgs/tofi
cp -a tofi/srcpkgs/tofi void-packages/srcpkgs/

cd void-packages
./xbps-src -A x86_64-musl binary-bootstrap
./xbps-src -A x86_64-musl pkg tofi
```

The resulting package is written under `hostdir/binpkgs/`. On a glibc x86_64 build host, use the `-A x86_64-musl` target for both commands.

## Releases

Successful builds from `main` publish an immutable, versioned GitHub Release. The tag format is `<version>_<revision>` (initially `0.9.1_1`), and the release contains the single installable package:

```
tofi-0.9.1_1.x86_64-musl.xbps
```

Download the package from [Releases](https://github.com/rmicro/tofi/releases), then install it on a compatible Void Linux system:

```sh
sudo xbps-install ./tofi-0.9.1_1.x86_64-musl.xbps
```

These are standalone package releases, not a signed, indexed XBPS repository.

## Validation and maintenance

Run the repository's lightweight checks before pushing:

```sh
bash -n srcpkgs/tofi/template
sh -n scripts/publish-release.sh
sh scripts/test-template.sh
```

When updating tofi:

1. Update `version` and the source `checksum` in `srcpkgs/tofi/template`.
2. Keep the XBPS revision at `1` for a new upstream version; increment it when packaging changes alter the built package.
3. Check the Void package template for changed dependencies or musl workarounds.
4. Run the validation checks and confirm the real `xbps-src -A x86_64-musl pkg tofi` build succeeds.
5. Test the resulting package on the reference Skylake hardware before making performance claims.

## References

- [Upstream tofi](https://github.com/philj56/tofi)
- [Void Linux tofi package](https://github.com/void-linux/void-packages/tree/master/srcpkgs/tofi)
- [Void Linux XBPS source packages](https://github.com/void-linux/void-packages)
- [rnicro/velotype](https://github.com/rmicro/velotype) and [rnicro/linux](https://github.com/rmicro/linux), used as examples for architecture-specific XBPS builds and release workflows.

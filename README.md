# tofi for Void Linux (x86_64-musl / Intel Skylake)

A hardware-specific Void Linux XBPS package for [tofi](https://github.com/philj56/tofi), targeting **x86_64-musl** and Intel Skylake CPUs, with the Intel Core i3-6100U as the reference processor.

This repository packages upstream tofi; it does not fork or modify the application source.

## Target and compatibility

- Distribution: Void Linux
- XBPS target: `x86_64-musl` only
- CPU target: Intel Skylake (`-march=skylake -mtune=skylake`)
- Reference CPU: Intel Core i3-6100U (2 cores / 4 threads)
- C library: musl
- Build system: Meson / Ninja

This is not a generic x86_64 binary. The Skylake compiler target can emit instructions unsupported by older x86_64 processors. It is not intended for pre-Skylake CPUs, glibc systems, or non-x86_64 architectures.

GitHub Actions builds the package on a hosted runner. The runner is only the build host; the XBPS target ABI and compiler flags select the device architecture. Build parallelism is therefore based on the runner, not the laptop's two CPU cores.

## Target-specific build

The package recipe follows Void Linux's `srcpkgs/tofi/template` and adds:

- `-march=skylake -mtune=skylake` for the Core i3-6100U CPU family.
- Meson's `-Doptimization=2` optimization level.
- Meson's `-Db_lto=true` for link-time optimization.
- `archs="x86_64-musl"` to restrict the package ABI.
- `musl-fts-devel` and `-lfts`, matching Void's musl-specific tofi fix.

LTO is enabled through Meson rather than manually adding `-flto` to linker flags; Void's Meson build helper selects `gcc-ar` for LTO archive handling.

The current package is **0.9.1-r2**. Revision 2 accounts for the LTO-enabled build output.

## Runtime profile based on the actual setup config

The [`examples/dwl-run.conf`](examples/dwl-run.conf) profile is based on [`rnicro/setup/HOME/.config/tofi/config`](https://github.com/rmicro/setup/blob/main/HOME/.config/tofi/config), rather than a generic theme.

The existing configuration is already doing the most important tofi startup optimization: it specifies a **font file path** (`/usr/share/fonts/noto/NotoSansMono-Regular.ttf`). Upstream documents that this bypasses Pango/Fontconfig font-name lookup and uses the direct HarfBuzz/Cairo path. It also already has a short 30-pixel top ribbon, horizontal results, no borders/outlines, disabled history sorting, and direct drun launching.

The only default runtime change in the example is `hint-font=false`. Upstream says disabling font hinting can speed text rendering when a font file path is used. At 14 pt it may be acceptable, but check glyph sharpness on the actual display; set it back to `true` if the text looks worse.

The profile intentionally preserves `num-results=0`, so all results that fit can be displayed. Upstream notes that specifying a fixed result count can reduce some horizontal-layout sizing work, but this option is a maximum-result cap. The profile includes `# num-results=8` as an opt-in experiment; uncomment it only if limiting the displayed choices is acceptable.

It also keeps `ascii-input=false` so Unicode matching remains correct, and `late-keyboard-init=false` so early keypresses are not missed.

Install the profile:

```sh
mkdir -p ~/.config/tofi
cp examples/dwl-run.conf ~/.config/tofi/config
```

The font path is taken from your current setup. Confirm it exists on the target system:

```sh
test -r /usr/share/fonts/noto/NotoSansMono-Regular.ttf
```

## Local build

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

Successful builds from `main` publish an immutable, versioned GitHub Release. The tag format is `<version>_<revision>` (currently `0.9.1_2`), and the release contains the single installable package:

```
tofi-0.9.1_2.x86_64-musl.xbps
```

Download the package from [Releases](https://github.com/rmicro/tofi/releases), then install it on a compatible Void Linux system:

```sh
sudo xbps-install ./tofi-0.9.1_2.x86_64-musl.xbps
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
2. Keep revision 1 for the initial packaging of a new upstream version; increment it when packaging changes alter the built package.
3. Check Void's template for changed dependencies or musl workarounds.
4. Run the validation checks and confirm the real `xbps-src -A x86_64-musl pkg tofi` build succeeds.
5. Benchmark the package on the reference Skylake laptop before claiming a runtime speedup.

## References

- [Upstream tofi](https://github.com/philj56/tofi)
- [Upstream performance notes](https://github.com/philj56/tofi#performance)
- [Upstream configuration reference](https://github.com/philj56/tofi/blob/master/doc/config)
- [Void Linux tofi package](https://github.com/void-linux/void-packages/tree/master/srcpkgs/tofi)
- [Meson built-in optimization and LTO options](https://mesonbuild.com/Builtin-options.html)
- [Void Linux XBPS source packages](https://github.com/void-linux/void-packages)
- [rnicro/velotype](https://github.com/rmicro/velotype) and [rnicro/linux](https://github.com/rmicro/linux), used as examples for architecture-specific XBPS builds and release workflows.

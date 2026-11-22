# tofi for Void Linux (x86_64-musl / Intel Skylake)

A hardware-specific Void Linux XBPS package for [tofi](https://github.com/philj56/tofi), targeting **x86_64-musl** and Intel Skylake CPUs, with the Intel Core i3-6100U as the reference processor.

This repository packages upstream tofi; it does not fork or modify the application source.

## Target and compatibility

- Distribution: Void Linux
- XBPS target: `x86_64-musl` only
- CPU target: Intel Skylake (`-march=skylake -mtune=skylake`)
- Reference CPU: Intel Core i3-6100U (2 cores / 4 threads)
- Memory/storage profile: low-memory laptop; avoid unnecessary build-time or runtime overhead
- Build system: Meson / Ninja
- C library: musl

This is not a generic x86_64 binary. The Skylake compiler target can emit instructions unsupported by older x86_64 processors. It is not intended for pre-Skylake CPUs, glibc systems, or non-x86_64 architectures.

GitHub Actions builds the package on a hosted runner. The runner is only the build host; the XBPS target ABI and compiler flags select the device architecture. Build parallelism is therefore based on the runner, not the laptop's two CPU cores.

## Target-specific build

The package recipe follows Void Linux's `srcpkgs/tofi/template` and adds:

- `-march=skylake -mtune=skylake` for the Core i3-6100U CPU family.
- Meson's `-Doptimization=2` release optimization level.
- Meson's `-Db_lto=true` for link-time optimization.
- `archs="x86_64-musl"` to prevent publishing binaries for other ABIs.
- `musl-fts-devel` and `-lfts`, matching Void's musl-specific tofi fix.

LTO is enabled through Meson rather than manually adding `-flto` to linker flags; Void's Meson build helper selects `gcc-ar` to handle LTO archives correctly.

The current package is **0.9.1-r2**. Revision 2 accounts for the new LTO-enabled build output.

## Runtime profile for dwl

For an interactive launcher, runtime startup matters more than tiny compiler-flag changes. Upstream documents that giving tofi a **font file path** bypasses Pango/Fontconfig font-name lookup and loads the font directly with HarfBuzz/Cairo. This is the main startup optimization in the included profile.

The repository includes [`examples/dwl-run.conf`](examples/dwl-run.conf), a compact top-of-screen, horizontal `tofi-run` profile. Before using it, replace its placeholder font path with an installed font file. For example:

```sh
fc-match -f '%{file}\n' 'DejaVu Sans Mono'
```

Copy the resulting path into the profile's `font` setting, then install it as your user config:

```sh
mkdir -p ~/.config/tofi
cp examples/dwl-run.conf ~/.config/tofi/config
# Edit ~/.config/tofi/config and set font to the real path printed by fc-match.
```

Run it with:

```sh
tofi-run
```

The profile also keeps the drawn window short, uses horizontal mode and a fixed result count, and disables font hinting. Upstream notes that fixed `num-results` helps the horizontal layout path, while `hint-font=false` only applies when a font file path is used. Check text quality at your display's scale and adjust `font-size` as needed.

I intentionally leave `late-keyboard-init=false`: upstream warns it can miss keypresses immediately after launch. `ascii-input=false` also stays enabled so Unicode matching remains correct. These are safer defaults for a daily launcher than chasing a marginal startup reduction.

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
- [Void Linux tofi package](https://github.com/void-linux/void-packages/tree/master/srcpkgs/tofi)
- [Meson built-in optimization and LTO options](https://mesonbuild.com/Builtin-options.html)
- [Void Linux XBPS source packages](https://github.com/void-linux/void-packages)
- [rnicro/velotype](https://github.com/rmicro/velotype) and [rnicro/linux](https://github.com/rmicro/linux), used as examples for architecture-specific XBPS builds and release workflows.

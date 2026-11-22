#!/bin/sh
set -eu

template="srcpkgs/tofi/template"
profile="examples/dwl-run.conf"
[ -s "$template" ] || {
    echo "Missing package template: $template" >&2
    exit 1
}
[ -s "$profile" ] || {
    echo "Missing dwl launcher profile: $profile" >&2
    exit 1
}

grep -Eq '^pkgname=tofi$' "$template"
grep -Eq '^version=[0-9]+\.[0-9]+\.[0-9]+$' "$template"
grep -Eq '^revision=[0-9]+$' "$template"
grep -Fq 'build_style=meson' "$template"
grep -Fq 'configure_args="-Doptimization=2 -Db_lto=true"' "$template"
grep -Fq 'archs="x86_64-musl"' "$template"
grep -Fq 'CFLAGS+=" -march=skylake -mtune=skylake"' "$template"
grep -Fq 'makedepends+=" musl-fts-devel"' "$template"
grep -Fq 'LDFLAGS+=" -lfts"' "$template"
grep -Fq 'https://github.com/philj56/tofi/archive/refs/tags/v' "$template"

checksum="$(sed -n 's/^checksum=//p' "$template")"
[ "${#checksum}" -eq 64 ] || {
    echo "Expected a 64-character source SHA-256 checksum." >&2
    exit 1
}
case "$checksum" in
    *[!0-9a-f]*)
        echo "Source checksum must be lowercase hexadecimal." >&2
        exit 1
        ;;
esac

grep -Fq 'horizontal = true' "$profile"
grep -Fq 'num-results = 8' "$profile"
grep -Fq 'hint-font = false' "$profile"
grep -Fq 'late-keyboard-init = false' "$profile"
grep -Fq 'ascii-input = false' "$profile"

if grep -Fq 'fix-32bit-tests.patch' "$template"; then
    echo "The 32-bit-only downstream patch must not be enabled in this x86_64 package." >&2
    exit 1
fi

echo "tofi Skylake/musl/LTO and runtime profile invariants passed"

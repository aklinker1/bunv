# Bunv

Zero config wrapper around [Bun](https://bun.sh/) that automatically downloads, manages, and executes the version of `bun` required by each of your projects.

So basically [`corepack`](https://github.com/nodejs/corepack) for Bun! But written in Zig for [basically zero overhead](#benchmark).

> This is my first Zig project, so if you know Zig, look at the code, and have feedback, please share it with me!

## Features

- [x] Automatic versioning for `bun`
- [x] Automatic versioning for `bunx`
- [x] `bunv` CLI
- [ ] Version files
   - [x] `package.json` support
      ```json
      {
        "packageManager": "bun@1.1.26"
      }
      ```
   - [ ] `.tool-versions` support
      ```txt
      bun 1.1.26
      ```
   - [ ] `.bun-version` support
      ```txt
      1.1.26
      ```
- [ ] Use the latest version of Bun when not in a project
- [ ] Look up the directory tree to find the version file

## Installation

Build from source:

1. Uninstall [`bun`] or remove `~/.bun/bin` from your path
2. Install [Zig](https://ziglang.org/)
3. Build the executables (`bun`, `bunx`, `bunv`)
   ```sh
   zig build -Doptimize=ReleaseFast --prefix ~/.bunv
   ```
4. Add `~/.bunv/bin` to your path:
   ```sh
   export PATH="$HOME/.bunv/bin:$PATH"
   ```
5. Double check that sure `which bun` outputs `~/.bunv/bin/bun`

## Usage

To use `bun` or `bunx`, just use it like normal:

```sh
$ bun i
$ bunx oxlint@latest
```

If you haven't installed a project's version of `bun`, you'll be prompted to install it when running any `bun` or `bunx` commands.

Bunv also ships it's own executable: `bunv`. Right now, it just lists the versions of Bun it has installed:

```sh
$ bunv
Installed versions:
  v1.1.26
    │  Directory: /home/aklinker1/.bunv/versions/1.1.26
    │  Bin Dir:   /home/aklinker1/.bunv/versions/1.1.26/bin
    └─ Bin:       /home/aklinker1/.bunv/versions/1.1.26/bin/bun
```

To delete a version of Bun, just delete it's directory:

```sh
$ rm -rf ~/.bunv/versions/1.1.26
```

If you're not in a project, Bunv will use the newest version installed locally or if there are none, it will download and install the latest release.

### Upgrading Bun

`bun upgrade` isn't going to do anything. Instead, update the version of bun in your `package.json`, `.bun-version`, or `.tool-versions` file and it will be installed the next time you run a `bun` command.

### GitHub Actions

The `setup/bun` action already supports all the version files Bunv supports - that means you don't have to install Bunv in CI - just use it locally.

## Benchmark

If you're using Bun, you probably love the CLI's incredible speed - so do I. That's why the only benchmark I focused on is how much overhead it takes for Bunv to lookup and execute the correct version of bun.

So this benchmark measures the time it takes for `bun --version` to run.

```sh
$ hyperfine -N --warmup 10 --runs 1000 '/home/aklinker1/.bunv/versions/1.1.26/bin/bun --version' '/home/aklinker1/.bunv/bin/bun  --version'
Benchmark 1: /home/aklinker1/.bunv/versions/1.1.26/bin/bun --version
  Time (mean ± σ):       1.5 ms ±   0.1 ms    [User: 1.0 ms, System: 0.4 ms]
  Range (min … max):     1.3 ms …   2.3 ms    1000 runs

Benchmark 2: /home/aklinker1/.bunv/bin/bun  --version
  Time (mean ± σ):       2.0 ms ±   0.1 ms    [User: 1.0 ms, System: 0.9 ms]
  Range (min … max):     1.7 ms …   2.3 ms    1000 runs

Summary
  /home/aklinker1/.bunv/versions/1.1.26/bin/bun --version ran
    1.37 ± 0.12 times faster than /home/aklinker1/.bunv/bin/bun  --version
```

1.5ms without `bunv` vs 2.0ms with it. While it's technically 1.37x slower, it's only ***0.5ms of overhead*** - unnoticable to a human.

> [!NOTE]
> `hyperfine` strruggles to accurately benchmark commands that exit in less than 5ms... If anyone knows a better way to benchmark this, please open a PR!

## Debugging

To print debug logs, set the `DEBUG` environment variable to `bunv`:

```sh
$ DEBUG=bunv bun --version
```

## Development

```sh
# Build all executables (bun, bunx, bunv) to ./zig-out/bin
$ zig build

# Build and run an executable
$ zig build bun
$ zig build bunx
$ zig build bunv

# Pass args to the executable
$ zig build
$ ./zig-out/bin/bun --version
$ ./zig-out/bin/bunx --version
$ ./zig-out/bin/bunv --version

# Build and install production executables to ~/.bunv/bin
$ zig build --release=fast --prefix ~/.bunv
```

## Release

Prebuild binaries for all platforms:

```sh
$ zig build --summary all -Doptimize=ReleaseFast -Dtarget=aarch64-macos
$ zig build --summary all -Doptimize=ReleaseFast -Dtarget=x86_64-macos
$ zig build --summary all -Doptimize=ReleaseFast -Dtarget=aarch64-linux
$ zig build --summary all -Doptimize=ReleaseFast -Dtarget=x86_64-linux
```

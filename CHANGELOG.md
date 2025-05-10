## [0.4.1](https://github.com/aklinker1/bunv/compare/v0.4.0...v0.4.1) (2025-05-10)


### Bug Fixes

* Kill the process if bun fails to install ([41c8409](https://github.com/aklinker1/bunv/commit/41c84091bec060ff5fab94dd596bffe4140170ef))



# [0.4.0](https://github.com/aklinker1/bunv/compare/v0.3.2...v0.4.0) (2025-04-10)


### Bug Fixes

* Add support for Zig 0.13 back ([#18](https://github.com/aklinker1/bunv/issues/18)) ([e2f094e](https://github.com/aklinker1/bunv/commit/e2f094ecc490dbe370c9dcb83009feb14c7a50c9))
* create parent directories before installation ([#22](https://github.com/aklinker1/bunv/issues/22)) ([50c15c8](https://github.com/aklinker1/bunv/commit/50c15c805d6aefb85878f5463407d7edb3c3cd74))
* gracefully handle UserAborted errors ([#20](https://github.com/aklinker1/bunv/issues/20)) ([c1501b8](https://github.com/aklinker1/bunv/commit/c1501b88a5177456fbae9dbeaf2900a81be76492))
* handle non-interactive terminals when prompting for version installation ([#19](https://github.com/aklinker1/bunv/issues/19)) ([72f2616](https://github.com/aklinker1/bunv/commit/72f26163edd36fd9dd68a0c58eb83e645e16be22))
* Ignore making config directory if it already exists ([#25](https://github.com/aklinker1/bunv/issues/25)) ([b855bbf](https://github.com/aklinker1/bunv/commit/b855bbf0b4353ff7600303714f54bdd18116ed03))


### Features

* add `BUNV_AUTO_INSTALL=1` environment variable ([#21](https://github.com/aklinker1/bunv/issues/21)) ([754c595](https://github.com/aklinker1/bunv/commit/754c595cefa0d31b1bd7cce49bd6c1dfab3b149c))
* add support for `.tool-versions` files ([#23](https://github.com/aklinker1/bunv/issues/23)) ([9bf6914](https://github.com/aklinker1/bunv/commit/9bf691457ea12065be4197c3f6286753b6757c42))
* Display message when no versions are installed ([#17](https://github.com/aklinker1/bunv/issues/17)) ([aac4b54](https://github.com/aklinker1/bunv/commit/aac4b54b66b6f06e99edeba5cb58b89c0a17d8cb))



## [0.3.2](https://github.com/aklinker1/bunv/compare/v0.3.1...v0.3.2) (2025-03-08)


### Bug Fixes

* Fix typos in logs ([0bbe92c](https://github.com/aklinker1/bunv/commit/0bbe92c6bb73ed3d597dbefa01b525b5d952c493))
* Support `.bun-version` file ([1c70d2b](https://github.com/aklinker1/bunv/commit/1c70d2bee4dd0b70ce5f9c9d97e10516b1f8cf25))



## [0.3.1](https://github.com/aklinker1/bunv/compare/v0.3.0...v0.3.1) (2024-09-21)


### Bug Fixes

* Properly ZIP release binaries for windows ([924458d](https://github.com/aklinker1/bunv/commit/924458daa81e331b6ce795907f8143972e4c4bc6))



# [0.3.0](https://github.com/aklinker1/bunv/compare/v0.2.1...v0.3.0) (2024-09-21)


### Features

* Add windows support ([#10](https://github.com/aklinker1/bunv/issues/10)) ([66f0b4d](https://github.com/aklinker1/bunv/commit/66f0b4d5dd3b7c69983ba23aa11106d2fb88e078))



## [0.2.1](https://github.com/aklinker1/bunv/compare/v0.2.0...v0.2.1) (2024-09-21)


### Bug Fixes

* Correctly sign executables for MacOS ([#9](https://github.com/aklinker1/bunv/issues/9)) ([e348ee2](https://github.com/aklinker1/bunv/commit/e348ee2c74d764d54ec43c400e55d3a3b00ad2df))
* Only respect 'bun@' packageManager prefix ([4ccf6da](https://github.com/aklinker1/bunv/commit/4ccf6dad5ffdccd526fbd9563033037c40c36311))



# [0.2.0](https://github.com/aklinker1/bunv/compare/fb821eab420c58371b0f38b4b5a7626840b508cd...v0.2.0) (2024-09-17)


### Bug Fixes

* Don't attempt to fetch the latest version when some exist locally ([97c082b](https://github.com/aklinker1/bunv/commit/97c082b5c8394e05421ebd754d024a1e93b8c17e))
* Look up current directory to find version file ([#2](https://github.com/aklinker1/bunv/issues/2)) ([1636c1e](https://github.com/aklinker1/bunv/commit/1636c1eec8da0d00ec3d53159b0005575f0ef54b))
* Various improvements ([#1](https://github.com/aklinker1/bunv/issues/1)) ([cbacc24](https://github.com/aklinker1/bunv/commit/cbacc24b4c892bb18d2a9325fdb9f881612654cf))


### Features

* Fetch latest release from GitHub if no versions are installed ([ea8d6fa](https://github.com/aklinker1/bunv/commit/ea8d6fa462ae24b2791d3bce9860508ebb368cef))
* Initial version management and bun/bunx aliases ([fb821ea](https://github.com/aklinker1/bunv/commit/fb821eab420c58371b0f38b4b5a7626840b508cd))




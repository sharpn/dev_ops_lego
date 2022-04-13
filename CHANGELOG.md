# Changelog

All notable changes to this project will be documented in this file.

## [1.4.0](https://github.com/sharpn/dev_ops_lego/compare/v1.3.0...v1.4.0) (2022-04-13)


### Features

* adding aws and kubernetes providers to fix the region ([ca14eae](https://github.com/sharpn/dev_ops_lego/commit/ca14eae8506db24919044bf97eb2d6909771e290))
* adding security groups so the nodes can talk to each other ([d86678b](https://github.com/sharpn/dev_ops_lego/commit/d86678bd185d229705f073ae2653dff56b942055))

## [1.3.0](https://github.com/sharpn/dev_ops_lego/compare/v1.2.2...v1.3.0) (2022-04-13)


### Features

* adding second worker pool to eks ([901ecf4](https://github.com/sharpn/dev_ops_lego/commit/901ecf4c609449d433854c64a8919cc6cf940b0d))

### [1.2.2](https://github.com/sharpn/dev_ops_lego/compare/v1.2.1...v1.2.2) (2022-04-13)


### Bug Fixes

* updating vpc routing to allow private subnets to access the interner ([cd082a0](https://github.com/sharpn/dev_ops_lego/commit/cd082a02177e67c526dfd83b2ba46888e240a8ec))

### [1.2.1](https://github.com/sharpn/dev_ops_lego/compare/v1.2.0...v1.2.1) (2022-04-12)


### Bug Fixes

* starting to work out how networks connect together ([bb4b729](https://github.com/sharpn/dev_ops_lego/commit/bb4b729dd33517102d81ae9d8b0af3f00c1fdaf5))

## [1.2.0](https://github.com/sharpn/dev_ops_lego/compare/v1.1.0...v1.2.0) (2022-04-12)


### Features

* starting work on eks module, creating security groups and main/worker nodes ([94adf1f](https://github.com/sharpn/dev_ops_lego/commit/94adf1f8fbe0f7453574f688355c757c4fdd4db0))


### Bug Fixes

* adding tags to vpc's ([606ccde](https://github.com/sharpn/dev_ops_lego/commit/606ccde9ede95156065a248349bb7cd353dbe5f2))

## [1.1.0](https://github.com/sharpn/dev_ops_lego/compare/v1.0.1...v1.1.0) (2022-04-12)


### Features

* refactoring vpc to add cluster tags ([e5acc10](https://github.com/sharpn/dev_ops_lego/commit/e5acc10b3bf1e22dcbf6c9f4d76e536a453d9679))

### [1.0.1](https://github.com/sharpn/dev_ops_lego/compare/v1.0.0...v1.0.1) (2022-04-12)


### Bug Fixes

* changing release config so it packages correct files ([e9beeb2](https://github.com/sharpn/dev_ops_lego/commit/e9beeb26d51f2ae2b50ae80e5b2516dde4612a45))

## 1.0.0 (2022-04-12)


### Features

* adding initial folder layout ([b819732](https://github.com/sharpn/dev_ops_lego/commit/b8197321243371c5db03bb7a929d59ccbbd999a0))
* adding module to create vpc with subnets and creating vpc ([212338a](https://github.com/sharpn/dev_ops_lego/commit/212338af5ad0cc069fdd9d2baba6684bcfbd2a5f))
* adding release config ([6d94739](https://github.com/sharpn/dev_ops_lego/commit/6d947393c6a8953e102f8c515b5c93bdadd2cc18))
* adding s3 backend and aws version lock ([3a924dd](https://github.com/sharpn/dev_ops_lego/commit/3a924ddb3e3721b969e7db0a3b3df6504f9daf4a))

# Contributing to healthbR

First off, thanks for considering contributing to healthbR! This package aims
to make Brazilian public health data accessible to researchers, and
contributions from the community are essential.

## Code of Conduct

Please note that healthbR is released with a
[Contributor Code of Conduct](CODE_OF_CONDUCT.md). By contributing to this
project you agree to abide by its terms.

## How to Contribute

### Bug Reports

If you find a bug, please open an issue on
[GitHub](https://github.com/SidneyBissoli/healthbR/issues) with:

- A minimal reproducible example (reprex)
- The output of `sessionInfo()`
- The healthbR version (`packageVersion("healthbR")`)

### Feature Requests

Have an idea for a new data source or function? Open an issue describing:

- The data source or feature
- Why it would be useful
- Links to the data source documentation (if applicable)

### Pull Requests

Want to contribute code? Great! Here is how:

1. Fork the repository and create a new branch from `main`
2. Follow the coding conventions below
3. Add tests for new functionality (we aim for >= 75% coverage)
4. Run `devtools::check()` and ensure no errors or warnings
5. Submit a pull request describing the changes

### Coding Conventions

- Use the native pipe `|>` (never `%>%`)
- Use `stringr::str_c()` instead of `paste0()`
- Comments in English, lowercase after `#`
- User messages via `cli::cli_inform()`, `cli::cli_warn()`, `cli::cli_abort()`
  (never `cat()`, `print()`, `message()`, `warning()`, `stop()`)
- Unicode escapes for special characters in strings (`\u00e7` for c-cedilla,
  `\u00e3` for a-tilde, etc.)
- Exported functions: `module_function()` pattern
- Internal functions: `.module_function()` pattern (dot prefix)
- Follow tidyverse style conventions

### Development Workflow

```r
# install development dependencies
devtools::install_dev_deps()

# run tests
devtools::test()

# check the package
devtools::check()

# check test coverage
covr::package_coverage()
```

## Questions?

Open a discussion on
[GitHub](https://github.com/SidneyBissoli/healthbR/issues) or contact the
maintainer.

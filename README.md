# Serhan Ekici's Website

## Overview

This ~200-line `gen` POSIX-compliant shell script is a flexible static site generator designed to transform my content into a fully functional and transparent webpage. The generator's core philosophy is **file-based modularity**, where every piece of content in a directory treated generated into one file. It combines dynamic content generation with version control metadata, to generate a Git-driven dynamic static webpage.

## Features

- **D.R.Y. - Do Not Repeat Yourself**

  - **Configuration Management**: The script uses a global conf file to define global settings, such as (`BUILD_DIR`, `CSS_FILE`, `PICS_DIR`, `site_lang`, `default_footer`, `site_description`), and values for custom global variables. Individual files or directories can also include their own `conf` file to override global settings or file-specific metadata.
  - **Dynamic Placeholder Replacement**: Placeholders like `${author_name}`, `${date_created}`, `${date_modified}`, and `${title}` are dynamically replaced with:
    - **Git Metadata**: For values like creation and modification timestamps, and author names.
    - **Custom Variables**: Defined in either the global `conf` file or file-specific `conf` files.

- **Version Control**:

  - Git metadata is integrated into every page, including:
    - **Creation and Modification Timestamps**: Automatically extracted from Git commit history.
    - **Page-Specific Commit History**: A chronological list of all commits affecting a page, complete with commit messages, author names, and direct links to the GitHub repository.

- **Markdown Injection**:

  - Converts Markdown files to HTML using `pandoc` and injects the output into specified placeholders within HTML templates.
  - Enables the combination of simple Markdown content with complex HTML layouts seamlessly.

- **Support for Modular Files**:

  - Modular content can be split into multiple files (e.g., `0.md`, `0.html`) and processed sequentially.
  - Markdown files are converted to HTML using `pandoc`, and prebuilt HTML files are appended directly, allowing for highly customizable page structures.

- **Automatic Index and RSS Generation**:
  - Automatically links generated pages in an `index.html` file.
  - Optionally adds pages to an RSS feed, complete with titles, timestamps, and descriptions.

## Dependencies

- **POSIX Tools**:
  - `sed`, `awk`, `realpath`, `date`: For text processing, file path resolution, and date formatting.
- **[pandoc](https://pandoc.org/)**: Converts Markdown files into HTML.
- **[jq](https://jqlang.github.io/jq/)**: Processes JSON, used for parsing GitHub API responses.
- **[git](https://git-scm.com/)**: Version control system for extracting commit metadata.
- **[curl](https://curl.se/)**: Interacts with the GitHub API to fetch commit history.
- **[shfmt](https://github.com/mvdan/sh#shfmt)**: Formats shell scripts for consistent code style.
- **[shellcheck](https://github.com/koalaman/shellcheck)**: Lints shell scripts to detect errors and enforce best practices.
- **[pre-commit](https://pre-commit.com/)**: Manages and runs hooks in Git repositories, ensuring code quality.
- **[Prettier](https://prettier.io/)**: Formats HTML files for consistent and readable output.

## Build Instructions

1. Ensure all dependencies are installed and accessible in your system's `PATH`.
2. Make the script executable:

```
chmod +x ./gen
```

3. Run the script

```
./gen
```

## TODO

- Containerization
- Linting and formatting Action
- shellcheck Action

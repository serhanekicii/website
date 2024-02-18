# Serhan Ekici's Website

## A Note on This

Hello! Thanks for checking out the code that runs my personal website. I believe in keeping my work open for transparency and so others can make suggestions or even point out my mistakes.

Please know that this script is a **personal project**, tailored specifically for my needs and workflow. It is not intended to be a general-purpose, reusable solution for everyone. If you're inspired by the approach, I encourage you to copy it, take ideas from it, or rewrite it completely to build something that perfectly fits _you_.

## What is This?

This is the engine for my personal website, built on a simple, ~300-line POSIX-compliant shell script. Both the generator and the site it builds are intentionally minimal. My goal was to create a website that was transparent and version-controlled from the ground up, deeply integrated with the tool I use every day: Git.

The core idea is that the site's content and its history are one and the same. Instead of a database or a complex CMS, this generator uses the Git repository itself to build pages, making the entire process transparent and **version-controlled by nature**.

## Core Concepts

### 📜 Git-Driven Content

The most unique aspect of this generator is its use of `git log` as a data source. Every page is infused with its own history.

- **Full Accountability**: Because every piece of content is tied to a commit, the generated site makes it easy to see **who made what change and when**. This provides a transparent and auditable history for every page, which in turn encourages contributions.
- **Creation & Modification Dates**: Timestamps are not manually entered; they are pulled directly from the first and last commits for a given file.
- **Page-Specific Commit History**: A complete, chronological list of every change made to a page is automatically included, complete with commit messages, author names, and links to the commit on GitHub.

### 🧩 File-Based Modularity

Each page on the site is generated from its own directory. This directory can contain an arbitrary number of content files, which are processed sequentially to build the final page. This allows you to break down complex pages into smaller, more manageable parts.

For example, a directory might contain:

- `00_intro.md`: A Markdown file for the introduction.
- `01_main_content.html`: A raw HTML file for a complex section.
- `styles.css`: Page-specific styles that get bundled automatically.
- `conf`: A configuration file to override global settings or Git metadata for that specific page.

### ⚙️ Simple Templating & Markdown

The script uses a straightforward placeholder system (`${variable_name}`) and comment-based replacement (`<!-- PLACEHOLDER -->`) to build pages. It supports writing content simply in Markdown while still allowing for the full power of HTML for layout.

### 🔗 Automatic Index & RSS

To keep everything linked, the script automatically links newly generated pages on the main `index.html` and adds them to an `rss.xml` feed if configured to do so.

## Dependencies

- **POSIX Utilities**: `printf`, `tr`, `cut`, `tail`, `head`
- **[cmark-gfm](https://github.com/github/cmark-gfm)**: For GitHub-Flavored Markdown conversion.
- **[git](https://git-scm.com/)**: For version control and metadata.
- **[pre-commit](https://pre-commit.com/)**: For managing Git hooks.

## Usage

1.  Ensure all dependencies are installed and available in your system's `PATH`.
2.  Make the script executable:
    ```bash
    chmod +x ./gen
    ```
3.  Run the script:
    ```bash
    ./gen
    ```

## TODO

- Implement a unified logging.
- Explore parallelism for faster builds.
- Cache Git metadata to avoid redundant `git log` calls.

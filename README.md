# serhanekici.com

My personal website. A simple, Git-driven static site.

This is a personal project, not a general-purpose tool. Feel free to copy ideas or rewrite it to fit your needs.

## What's this?

A ~400-line POSIX shell script that builds my website. Instead of a database or CMS, it uses the Git repository itself as the data source — timestamps, authors, and change history are pulled directly from commits.

**Why POSIX?** POSIX is a standard that ensures shell scripts work across Unix-like systems. This means the script runs on Linux, macOS, FreeBSD, OpenBSD, and any other POSIX-compliant system without modification.

## Features

**Git-Driven Content**

- Creation and modification dates from `git log`
- Each page includes its full commit history with links to GitHub
- Every change is accountable and transparent

**File-Based Modularity**

Each page is a directory named after its output file (e.g., `contact.html/`, `highlights.html/`). Inside:

```
contact.html/
├── 0.html      # HTML content (or 0.md for Markdown)
├── 0.css       # Optional page-specific styles
└── conf        # Page metadata (title, description, flags)
```

The `conf` file controls behavior:

- `title`, `description` — metadata and SEO
- `is_markdown="true"` — convert `.md` files to HTML
- `link_index="true"` — add to homepage post list
- `link_rss="true"` — include in RSS feed
- `add_header/add_footer="true"` — wrap with site header/footer

Placeholders like `${title}` in templates are replaced at build time. The script aggregates all `.html`/`.md`/`.css` files in the directory, applies the header/footer, and outputs to `build/`.

**No JavaScript Required**

- Light/dark theme via CSS `prefers-color-scheme` (GitHub colors)
- Active nav highlighting injected at build time
- Syntax highlighting via chroma (build-time)

**SEO**

- Canonical URLs and Open Graph tags
- JSON-LD structured data (WebSite, Person, Article schemas)
- Sitemap with `lastmod` from Git

## Quick start

```sh
./gen
```

Built files go to `build/`.

## Dependencies

- [cmark-gfm](https://github.com/github/cmark-gfm) for Markdown
- [chroma](https://github.com/alecthomas/chroma) for syntax highlighting
- [git](https://git-scm.com/)
- Standard POSIX utilities

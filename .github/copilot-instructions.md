# Copilot Instructions — Raining Graces Birth Services

## Project Overview

This is a **Jekyll static site** for Robin Spaid's birth doula business, "Raining Graces Birth Services," serving the OKC Metro area. The site showcases Robin's services, client testimonials, blog posts, and certifications. It is deployed via GitHub Actions to [https://www.raininggraces.com](https://www.raininggraces.com).

---

## Tech Stack

- **Jekyll** — static site generator (Liquid templating, YAML front matter)
- **Bulma 0.8.2** — CSS utility framework, loaded via CDN in `_sass/main.scss`
- **SCSS** — custom overrides in `_sass/main.scss`, compiled to `assets/css/style.css`
- **Font Awesome** — icon library via CDN kit in `_includes/head.html`
- **Simple Jekyll Search** — client-side blog search powered by `search.json`
- **jekyll-feed** — generates `/feed.xml` RSS feed
- **jekyll-admin** — local CMS at `http://localhost:4000/admin` (development only)
- **GitHub Actions** — builds and deploys on push to `master`

---

## Key Files & Where Things Live

| What you want to change | File(s) |
|---|---|
| Site title, bio, contact info, social handles | `_config.yml` |
| Homepage hero banner | `_includes/showcase.html` + `_config.yml` (`heroimage`, `title`, `description`) |
| About section | `_includes/about.html` + `_config.yml` (`author-name`, `author-about`, `author-image`) |
| Contact section (social links, phone, email) | `_includes/contact.html` + `_config.yml` |
| Navigation bar | `_includes/navbar.html`, `_includes/dropdown.html` |
| Client testimonial list/grid | `_data/clients.yml` (data) + `client/*.md` (full pages) |
| Blog posts | `_posts/YYYY-MM-DD-title.md` |
| "What is a Birth Doula?" page | `what-is-a-birth-doula.md` |
| Education & certifications page | `education-skills.md` |
| Custom CSS | `_sass/main.scss` |
| Page layouts | `_layouts/` (default, page, post, blog, client, clients) |
| Reusable HTML fragments | `_includes/` |
| Images | `assets/images/` |
| PDF documents (certificates) | `assets/docs/` |
| SEO/Open Graph meta tags | `_includes/meta.html` |
| Blog search index | `search.json` |

---

## Conventions & Patterns

### Liquid / Jekyll

- Site-wide variables are accessed as `{{ site.variable-name }}` (from `_config.yml`).
- Page-specific variables are accessed as `{{ page.variable }}` (from front matter).
- Use `{{ '/assets/...' | relative_url }}` for local asset paths in includes and layouts.
- Use `{{ site.url }}{{ site.baseurl }}/path` for full absolute URLs.
- Layouts wrap via `layout: compress` → the actual layout → page content.

### Front Matter

Every page/post must have front matter. Common fields:

```yaml
---
title: "Page Title"
layout: page        # or post, default, client, clients, blog
---
```

Posts additionally use:
```yaml
---
layout: post
title: "Post Title"
post-image: "../assets/images/image.jpg"
description: "Short one-liner for the card preview"
tags:
  - doula
  - blog
---
```

### Client Testimonials

Client data flows from two sources that must stay in sync:
1. `_data/clients.yml` — drives the card grid on `/clients` and the short previews.
2. `client/name.md` — the full testimonial page (`layout: client`).

The `link` field in `clients.yml` must match the path to the Markdown file in `client/`.

### Image Handling in Client Cards

- Regular client photos: use standard `is-3by1` Bulma figure (background-image CSS).
- Spinning Babies class reviews (no personal photo): add `fit: contain` in `clients.yml` — this uses `client-img-contain` CSS class for logo display.

---

## Common Tasks

### Add a blog post

Create `_posts/YYYY-MM-DD-slug.md` with post front matter. Use `--future` flag when serving locally if the date is in the future.

### Add a client testimonial

1. Add image to `assets/images/`.
2. Append entry to `_data/clients.yml` (name, image, link, description).
3. Create `client/name.md` with `layout: client` and the full testimonial text.

### Add a page to the "MORE" navbar dropdown

Edit `_includes/dropdown.html` — add the page URL to the `if` condition.

### Update Robin's bio

Edit the `author-about` field in `_config.yml`. Supports Markdown. The `---` separator between paragraphs renders as a horizontal rule.

### Change contact info

- Phone number: update `phone` in `_config.yml`.
- Email: update `email` in `_config.yml`.
- Instagram: update `instagram_username` in `_config.yml`.
- Facebook Messenger button: update `facebook_username` in `_config.yml`.

### Add a certificate/document

1. Place the PDF in `assets/docs/`.
2. Link to it in `education-skills.md` or wherever relevant: `[Certificate](/assets/docs/filename.pdf)`.

---

## Deployment

- **CI/CD:** GitHub Actions (`.github/workflows/jekyll.yml`) builds on every push to `master`.
- Posts with future dates are included in the build (`--future` flag).
- The site is hosted externally (not GitHub Pages) — the workflow only builds; deployment is handled separately.

---

## Things to Watch Out For

- **`_config.yml` changes require a Jekyll restart** — hot-reload does not pick them up.
- **Drafts** are created by prefixing the filename with `_` (e.g., `_posts/_2026-01-01-draft.md`). Remove the leading `_` to publish.
- The Bulma version is **pinned at 0.8.2** via CDN. Do not upgrade without testing layout — newer versions may have breaking CSS changes.
- Font Awesome is loaded via a kit script with a specific kit ID in `head.html`. Do not change or remove it.
- The `jekyll-admin` gem is development-only. It should not affect the production build but is excluded via `_config.yml`'s `exclude` list implicitly by being a group plugin.
- The `_layouts/compress.html` layout strips whitespace from HTML output — avoid JavaScript that relies on whitespace inside string literals.
- The `_includes/contact.html` conditionals use `{% unless site.field == %}` (empty string comparison) — this is the existing pattern for toggling social links; follow it when adding new ones.
- Image paths in `_posts` front matter use `../assets/images/` (relative) because posts are served under `/blog/`. Everywhere else use `/assets/images/` (absolute from root).

# Raining Graces Birth Services

Website for **Robin Spaid**, birth doula and Spinning Babies® Certified Parent Educator serving the OKC Metro area.

🌐 **Live site:** [https://www.raininggraces.com](https://www.raininggraces.com)

---

## Tech Stack

| Technology | Purpose |
|---|---|
| [Jekyll](https://jekyllrb.com/) | Static site generator |
| [Bulma](https://bulma.io/) 0.8.2 | CSS framework (loaded via CDN) |
| [Poppins](https://fonts.google.com/specimen/Poppins) | Body font (Google Fonts) |
| [Font Awesome](https://fontawesome.com/) | Icons |
| [Simple Jekyll Search](https://github.com/christian-fei/Simple-Jekyll-Search) | Blog search |
| [jekyll-feed](https://github.com/jekyll/jekyll-feed) | RSS feed |
| [jekyll-admin](https://jekyll.github.io/jekyll-admin/) | Local CMS UI |
| GitHub Actions | CI/CD build & deploy |

Based on the [WhatATheme](https://github.com/thedevslot/WhatATheme) theme (GNU GPLv2).

---

## Local Development

### Prerequisites

- Ruby (see `.ruby-version` for the exact version)
- Bundler (`gem install bundler`)

### Setup & Run

```bash
bundle install
bundle exec jekyll serve
```

The site is served at `http://localhost:4000` by default.  
The jekyll-admin CMS is available at `http://localhost:4000/admin`.

To include future-dated posts (useful when writing ahead):

```bash
bundle exec jekyll serve --future
```

---

## Repository Structure

```
.
├── _config.yml          # All site-wide settings (title, bio, social, contact)
├── _data/
│   └── clients.yml      # Client testimonial list (name, image, link, description)
├── _includes/           # Reusable HTML partials
│   ├── navbar.html      # Top navigation bar
│   ├── showcase.html    # Hero / homepage banner
│   ├── about.html       # About section (pulls from _config.yml)
│   ├── contact.html     # Contact section (social links + phone/email)
│   ├── footer.html      # Footer
│   ├── client-card.html # Card grid used on /clients page
│   ├── blog-card.html   # Card used in blog listing
│   ├── dropdown.html    # "MORE" navbar dropdown
│   ├── head.html        # <head> tag (links CSS/fonts)
│   ├── meta.html        # SEO & Open Graph meta tags
│   ├── search.html      # Search input widget
│   └── blogpage-heading.html # Blog page heading + search bar
├── _layouts/
│   ├── default.html     # Homepage (hero + about + contact)
│   ├── page.html        # Generic info page
│   ├── post.html        # Blog post
│   ├── blog.html        # Blog listing page
│   ├── client.html      # Individual client testimonial page
│   ├── clients.html     # Client grid listing
│   ├── 404.html         # 404 error page
│   └── compress.html    # HTML minification wrapper
├── _posts/              # Blog posts (filename: YYYY-MM-DD-title.md)
├── _sass/
│   └── main.scss        # Custom CSS overrides
├── assets/
│   ├── css/             # Compiled stylesheet output
│   ├── docs/            # PDF certificates and documents
│   ├── images/          # All site images
│   └── js/              # JavaScript (simple-jekyll-search)
├── client/              # Individual client testimonial pages (Markdown)
├── index.md             # Homepage (uses `default` layout)
├── blog.md              # Blog listing page
├── clients.md           # Clients grid page
├── what-is-a-birth-doula.md  # "What is a Birth Doula?" info page
├── education-skills.md  # Education & certifications page
├── search.json          # JSON index for blog search
├── 404.md               # 404 page
├── Gemfile              # Ruby dependencies
└── .github/workflows/
    └── jekyll.yml       # GitHub Actions build workflow
```

---

## How to Update Common Content

### Site-Wide Settings (`_config.yml`)

All primary settings live here. After editing, restart `jekyll serve` to see changes.

| Setting | Description |
|---|---|
| `title` | Site name shown in navbar and browser tab |
| `description` | Subtitle shown on the hero banner |
| `url` | Full production URL (no trailing slash) |
| `email` | Contact email |
| `phone` | Contact phone number (used in the contact section) |
| `instagram_username` | Instagram handle |
| `facebook_username` | Facebook Messenger ID for the "Message Me" button |
| `facebook_page` | Facebook Page ID for the social icon link |
| `author-name` | Doula's name |
| `author-about` | Bio text (supports Markdown) |
| `author-image` | Path to headshot image |
| `heroimage` | Background image path for the homepage hero section |
| `contact-badge-image` | Badge image shown in the contact section |
| `google-analytics` | Google Analytics tracking ID (leave blank to disable) |
| `site-keywords` | Comma-separated SEO keywords |

---

### Adding a Blog Post

1. Create a new file in `_posts/` named `YYYY-MM-DD-your-post-title.md`.
2. Add the front matter at the top:

```yaml
---
layout: post
title: "Your Post Title"
post-image: "../assets/images/your-image.jpg"
description: "A short one-line description"
tags:
  - doula
  - blog
---
```

3. Write the post content in Markdown below the front matter.
4. Add the image file to `assets/images/` if it's a new image.

> **Drafts:** Prefix the filename with `_` (e.g., `_2026-01-01-draft.md`) to prevent it from being published.

---

### Adding a Client Testimonial

Client testimonials appear on the `/clients` page and individual testimonial pages.

**Step 1 — Add the client image** to `assets/images/` (e.g., `jane-client.jpg`).

**Step 2 — Add an entry to `_data/clients.yml`:**

```yaml
- name: Jane
  image: /assets/images/jane-client.jpg
  link: /client/jane
  description: A short preview of the testimonial shown on the card...
```

For Spinning Babies class testimonials (no personal photo), use the logo with `fit: contain`:

```yaml
- name: Jane
  image: /assets/images/Spinning-Babies-logo-red-transparent.png
  link: /client/jane
  fit: contain
  description: My husband and I took a private Spinning Babies class with Robin...
```

**Step 3 — Create the testimonial page** at `client/jane.md`:

```markdown
---
title: Jane
layout: client
---

*Full testimonial text goes here.*
```

---

### Updating the Navbar Dropdown ("MORE" menu)

The dropdown is controlled in `_includes/dropdown.html`. It checks each page's URL against a hardcoded list. To add a page to the dropdown, add its URL to the `if` condition:

```liquid
{% if sitepage.url=='/what-is-a-birth-doula' or sitepage.url=='/clients' or sitepage.url=='/education-skills' or sitepage.url=='/your-new-page' %}
```

Make sure the new page has a `title` in its front matter.

---

### Adding / Updating Pages

Static info pages (like `what-is-a-birth-doula.md`) use the `page` layout:

```yaml
---
title: Page Title
layout: page
---

Page content in Markdown here.
```

Place the file in the root of the repository. The page will be available at `/your-page-filename`.

---

### Adding Images or Documents

- Images → `assets/images/`
- PDFs / documents → `assets/docs/`
- Reference them in Markdown with an absolute path: `/assets/images/filename.jpg`
- Or in Liquid templates using: `{{ '/assets/images/filename.jpg' | relative_url }}`

---

## Deployment

The site is built and deployed automatically via GitHub Actions (`.github/workflows/jekyll.yml`) on every push to the `master` branch.

To manually trigger a build, push any commit to `master`.

---

## Known Issues & Notes

- The `_includes/search.html` widget uses `id="search-input"`, but the blog layout's SimpleJekyllSearch config references `document.getElementById('search')`. The outer container div in `search.html` carries `id="search"`, so search works as expected.
- Future-dated posts are included in the GitHub Actions build (`--future` flag is set). Remove that flag if you want future posts to be hidden until their date.
- The jekyll-admin gem is pinned to `0.9.0` in the `Gemfile`. It is only used for local editing and is not included in the production build.


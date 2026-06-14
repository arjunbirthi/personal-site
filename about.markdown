---
layout: post
title: About
permalink: /about/
date: 2026-05-06
tag: preview
---

This page is a temporary design preview. Once the layout looks right, the placeholder text below will be replaced with a real about. The opening paragraph is intentionally long so you can see how the drop cap renders against several lines of wrapped prose — the floated capital should sit at the left margin while the surrounding text settles around it cleanly. Old-style numerals show up best in stretches with figures: years like 1847 or 2026, page references like p. 124, or a price like $19.95. The digits should descend below the baseline rather than sit at uniform height like they would in a spreadsheet.

The second paragraph should have a first-line indent and no top margin — the new paragraph is identified by the indent alone, not by a gap. This is how prose has been set in books for centuries, and it reads as one continuous flow of thought rather than as discrete blocks separated by whitespace.

A third consecutive paragraph confirms the rhythm holds. The indent is the only signal of a paragraph break, and the body of the page reads as a single river of text.

## A subheading like this

The first paragraph after a heading should sit flush left, with no indent — because it opens a new section, the same way book chapters open without an indent. The h2 itself should render in uppercase with letter-spacing in the muted heading color.

This is the second paragraph in the section, which should pick up the indent again.

> Blockquotes get a left rule in the soft border color and italic prose. They should sit comfortably in the parchment field, set off from the body without dominating it. Multi-line quotes wrap inside the rule.

After a blockquote, the next paragraph is also flush left — the `p + p` selector only triggers on truly adjacent paragraphs, so any non-paragraph element between them resets the chain. That's the correct book-typography behavior.

Inline elements like `code spans` and [hyperlinks](https://jekyllrb.com) should retain their styling — code in a soft tinted box, links underlined in the muted border color and darkening on hover.

A short list, to confirm article-body lists still render with bullets and proper indentation:

- One item, to verify the disc bullet appears
- Another item, to verify the spacing between list items feels right
- A third for good measure

---

The horizontal rule above should render as a centered ✦ ornament rather than a plain line. It marks a scene break — a stronger pause than a paragraph break but lighter than a section heading.

After the ornament, prose resumes. The paragraph immediately following the rule should be flush left, since the `<hr>` resets the paragraph chain. From here, indented paragraphs should pick up again.

This second paragraph after the ornament should be indented — confirming the rhythm continues once we're back in continuous prose. Numbers like 3, 14, and 1592 here are also a test of how digits look mid-sentence.

A final paragraph closes the preview, also indented, with one last digit at the end: 2026.

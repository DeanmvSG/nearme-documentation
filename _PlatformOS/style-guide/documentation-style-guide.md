---
title: PlatformOS Documentation Style Guide
permalink: /style-guide/documentation-style-guide
---

Thank you for contributing to our documentation!

To keep the tone and style of our documentation consistent, we created this style guide that contains organization, writing, style, and image guidelines for both the user and developer documentation of the PlatformOS marketplace solution.

The style guide contains writing guidelines for:

* Technical content (e.g. language, tone, etc.)
* Each content type in our documentation (e.g. tutorials, release notes, etc.) and corresponding documentation templates (where applicable)

## Writing guidelines

### Audience

We have identified the following proto-personas using our product and visiting our documentation site.

Proto-personas are descriptions for the types of users that will be interacting with our documentation site. The user personas help us share a specific, consistent understanding of various audience groups. Proposed solutions can be guided by how well they meet the needs of individual user personas. Features can be prioritised based on how well they address the needs of one or more personas.

[to be added: images about personas]

Address these personas when writing documentation.

### Language, tone and style

**Language**
Use U.S. English according to the Chicago Manual of Style.

**Present tense**
Use present tense and try to only use future tense when you need to emphasize that something occurs later, from the users' perspective.

Example:

* Use: PlatformOS prompts you to save your changes.
* Avoid: PlatformOS will prompt you to save your changes.

**Second person**
Talk to the users in the second person, and address the user as “you”. Avoid the use of gender-specific, third-person pronouns such as he, she, his, and hers.
Exception: Use the first-person singular pronoun “I” in the question part of FAQs.

Example:

* Use: Click ‘Save’ to save your changes.
* Avoid: The user has to click ‘Save’ to save his changes.

**Active voice**
Write in active voice. Active voice makes the performer of the action (usually the user) the subject of the sentence. \* Active-voice sentences are more direct and easier to understand than passive-voice sentences.

Example:

* Use: Click the ‘OK’ button to save your changes.
* Avoid: Changes will be saved after clicking the OK button.

**Capitalization**
Title case topic titles (each major word is uppercase). Sentence case headings (only the initial word is uppercase). Don’t use terminal punctuation in titles and headings unless a question mark is required.

Example:

* Use: (title) Creating Your PlatformOS Marketplace
* Avoid: (title) Creating your PlatformOS marketplace

**Punctuation**
Use the serial comma (the comma preceding the “and” before the last element in a list) except in titles, headlines and subheads.

Example:

* Use: List of all APIs, Liquid filters, and GraphQL schema
* Avoid: List of all APIs, Liquid filters and GraphQL schema

**Lists**
Use numbered lists for sequential task steps, and bullet lists for sets of options, notes, and the like. Only use a list if it has at least two items in it.

Precede an ordered or bulleted list with a sentence or phrase ending in a colon.

Begin each item with a capital letter. Complete sentences in a list should have a period at the end. If a line item is not a complete sentence, do not use a period. If you are breaking a sentence into a list, periods aren't necessary.

Be consistent, if possible, when writing the items in the list. Make them "parallel." E.g. start each item with a verb in the same tense and form.

## Format

Use Markdown formatting for all documentation content (except auto-generated API reference documentation).

[Markdown cheat sheet](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet)

### Headings

Headings help users find relevant information. ([Click here to learn more about the importance of headings.](https://m.eliteediting.com.au/what-are-headings-and-why-are-they-important/))

Don't use `#` (h1) headings in your articles, as they should be reserved for article titles.

Use `##` (h2) headings to separate important sections of the article. They are automatically anchored, so they make direct linking possible.

Use `###` (h3) headings as you see fit to improve readability and scannability of your content.

### Code examples

Code examples are probably the most important part of the documentation—the more there are, the better. There is a built-in code highlighter that works for many different programming languages.

Wrap inline snippets of code with `.

To add a code sample, use the <code>```</code> block, followed by the syntax highlighter language you want to use:

<pre class="highlight">
```javascript
&lt;h1&gt;Code.ruby = 'awesome'&lt;/h1&gt;
&lt;script&gt;
document.write('attack');
&lt;/script&gt;
```</pre>

which will result in

```javascript
<h1>Code.ruby = 'awesome'</h1>
<script>
document.write('attack');
</script>
```

To add liquid markup examples, wrap the whole block in the <code>{{ "{% raw "}}%}</code> tag:

<pre class="highlight">
{{ "{% raw "}}%}
```liquid
{% if value != blank %}
  Show my {{ "{{ value "}}}}
{% endif %}
```
{{ "{% endraw "}}%}</pre>

### Tables

Use tables to describe tabular data.

**Table example**

<pre class="highlight">
{% raw %}
| Unit          | Shortcut                       |
|---            |---                             |
| Mile          | `mi` or `miles`                |
| Meter         | `m` or `meters`                |
| Yard          | `yd` or `yards`                |
{% endraw %}
</pre>

If you have trouble remembering the syntax, don't worry, just use a [Markdown Tables Generator](https://www.tablesgenerator.com/markdown_tables) to speed things up.

### Screenshots, images

Images should be JPG or PNG files.

Use screenshots to:

* Visualize the flow/process
* Visualize a concept
* Show the result of browser rendering (if helpful)

Don't use screenshots to show:

* Code (use Markdown code examples instead)
* Example server response (use Markdown code examples instead)
* Form configuration view (use Markdown code examples instead)
* Table with parameters description (use Markdown table instead)

[to be added: information about uploading and linking to images]

### Videos

**Screencasts**
Upload videos to Youtube, and insert the generated embed code. Uncheck "Show suggested videos when the video finishes.", so that the embed code Youtube generates looks like this:

```html
<iframe width="560" height="315" src="https://www.youtube.com/embed/cKbaP-8-VFE" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>
```

**Terminal sessions**
Record and share your terminal sessions (where applicable) with [asciinema](https://asciinema.org/).

## Style guides for content types

### API reference documentation

### Documentation overview page

### Quickstart guides

Quickstart guides target the newcomer audience segment, and play an important role in the adoption of our product. Because newcomers starting to work with PlatformOS and implement our APIs face many obstacles (steep learning curve, unfamiliar structure, domain, and ideas behind the API, difficult to figure out where to start), quickstart guides should make the learning process easier for them.

Many users learn best by doing, so a quickstart guide should include steps that walk the user through the process of completing a task. The guide should be short and simple, and list the minimum number of steps required to complete a meaningful task (e.g., creating a PlatformOS marketplace).

Quickstart guides usually have to include information about the domain and introduce domain-related expressions and methods in more detail. It’s safest to assume that the user has never before heard of our service.

**[Quickstart guide template]()**

### Tutorials

### How-to guides

### Release notes

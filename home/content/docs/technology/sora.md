---
title: "🤖 Sora – Generative Diagram Technology"
slug: sora
template: rotkeeper-doc.html
version: "0.2.5-pre"
updated: "2025-06-02"
description: "Overview of Sora, a generative AI technology for creating lightweight infographics via prompts."
tags:
  - technology
  - generative-ai
  - graphics
  - chatgpt
asset_meta:
  name: "sora.md"
  version: "0.1.0"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# 🤖 Sora – Generative Diagram Technology

Sora is a lightweight generative‐AI technology we leverage to create on‐the‐fly, lightweight infographics using plain‐text prompts. Rather than embedding large image files in our documentation, we store **seed prompts** that a compatible Sora client (or other AI renderer) can interpret to produce graphics locally or in the browser.

## Why Sora?

- **Future‐Proofing**
  AI models evolve rapidly. By storing the underlying prompt instead of a static PNG, we can regenerate, tweak, or restyle graphics anytime without re‐exporting large assets.
- **Lightweight Repos**
  No bulky image files—just readable text prompts that describe node layouts, color palettes, and iconography.
- **Consistency**
  Using a shared “preset” approach, all Rotkeeper diagrams maintain a cohesive look and feel across documentation.

## How Sora Works

1. **Prompt‐Based Generation**
   Writers include a fenced code block named `sora-prompt` in Markdown. This block contains YAML‐like instructions:
   - **Color Palette**
   - **Font & Icon Styles**
   - **Node Definitions & Layout**
   - **Edges & Flow**
2. **AI Rendering**
   A Sora‐aware client (locally or via a browser plugin) parses the prompt and passes it to an LLM+renderer pipeline. The pipeline translates the instructions into an SVG (or PNG) diagram matching the specified style.
3. **Embed vs. Prompt**
   Instead of embedding binary images, we embed only the prompt. When needed, the diagram can be generated into a lightweight SVG or inlined as an image.

## Example Sora Prompt

Below is a sample `sora-prompt` block used to generate the Rotkeeper shell‐script workflow diagram. Copy, edit, and re‐run in your Sora client to see the graphic.

```sora-prompt
preset_name: "rotkeeper_pastel_workflow_v1"
color_palette: ["#FDEBD0", "#AED6F1", "#A3E4D7", "#F9E79F", "#F5B7B1"]
font_family: "Rounded Sans Serif"
icon_style: "simple line-art with rounded corners and subtle drop shadows"

title: "Rotkeeper Core Script Workflow"
subtitle: "From expand → render → scan (in pastel tones)"

layout:
  orientation: vertical
  nodes:
    - id: "rotkeeper.sh"
      label: "rotkeeper.sh"
      shape: rounded_rectangle
      fill_color: "#FDEBD0"
      icon: "terminal"
      icon_color: "#A3E4D7"
    - id: "rc-expand.sh"
      label: "rc-expand.sh"
      shape: rounded_rectangle
      fill_color: "#AED6F1"
      icon: "document"
      icon_color: "#F9E79F"
      caption: "# generate markdown + structure"
    - id: "rc-render.sh"
      label: "rc-render.sh"
      shape: rounded_rectangle
      fill_color: "#A3E4D7"
      icon: "transform"
      icon_color: "#F5B7B1"
      caption: "# turn .md → .html"
    - id: "rc-scan.sh"
      label: "rc-scan.sh"
      shape: rounded_rectangle
      fill_color: "#F9E79F"
      icon: "magnifier"
      icon_color: "#AED6F1"
      caption: "# audit + compare against manifest"
  edges:
    - from: "rotkeeper.sh" to: "rc-expand.sh"
    - from: "rc-expand.sh" to: "rc-render.sh"
    - from: "rc-render.sh" to: "rc-scan.sh"

background_texture: "light_paper_grain"
drop_shadow: true
annotation_style: "handwritten_friendly"
```

## Integrating ChatGPT

Most of our documentation content—including example prompts, code stubs, and guidance—has been assisted or generated by ChatGPT. We use ChatGPT almost exclusively to draft:

- Script stubs and logic
- Documentation outlines and explanations
- Sora prompt examples

> **Why ChatGPT?**
> - Rapid prototyping of shell script logic.
> - Generating detailed explanations and context.
> - Refining natural‐language prompts for generative AI.

If you look at our Git history, many commit messages and file diffs reference ChatGPT as the originator of content. We view ChatGPT as a “co‐author” rather than a static resource, and we encourage contributors to inspect, tweak, and extend AI‐generated content to suit their needs.

## Getting Started

1. **Install a Sora Client**
   - Locate a compatible CLI (e.g., `sora-cli`) or browser plugin that recognizes the `sora-prompt` block.
2. **Generate a Diagram**
   - Run: `sora-cli render path/to/your-doc.md::\`\`\`sora-prompt\`\`\``
   - Watch the tool output an SVG/PNG file in `output/graphics/`.
3. **Tweak & Iterate**
   - Modify the prompt block to adjust colors, fonts, or node arrangement.
   - Re-run until you achieve the desired style.

## Future Directions

- Support multiple “graphic presets” (dark mode, corporate style).
- Automatically embed generated SVGs in HTML output when building docs.
- Expand to other diagram types (sequence diagrams, state machines, etc.).
- Explore direct integration of ChatGPT + Sora for dynamic diagram generation in the browser.

---

*Document version 0.2.5-pre (2025-06-02) – maintained by the Rotkeeper Ritual Council.*
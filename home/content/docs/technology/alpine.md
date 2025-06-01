
---
title: "Alpine.js Examples"
slug: alpine
template: rotkeeper-doc.html
version: "v0.2.3-pre"
updated: "2025-06-01"
description: "Collection of Alpine.js usage examples for Rotkeeper project."
tags:
  - rotkeeper
  - alpine
  - javascript
  - ui
asset_meta:
  name: "alpine.md"
  version: "v0.2.3-pre"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# 🏔️ Alpine.js Examples and Documentation

Alpine.js is a lightweight JavaScript framework for declarative DOM behavior. This page collects a variety of Alpine usage examples used across the Rotkeeper project for inspiration, reference, and aesthetic abuse.

## Basic Table with Actions

This example demonstrates rendering a table of data with Alpine.js, wiring up row actions, and using `x-for` to iterate over items. Each row provides buttons to select, delete, or update items, all handled with Alpine event bindings.

```html
<div x-data="tableDemo">
  <table>
    <tbody>
      <template x-for="item in data" :key="item.id">
        <tr :class="{selected: selected === item.id}">
          <td x-text="item.id"></td>
          <td x-text="item.label"></td>
          <td>
            <button @click="select(item.id)">Select</button>
            <button @click="deleteItem(item.id)">Delete</button>
            <button @click="update(item.id)">Update</button>
          </td>
        </tr>
      </template>
    </tbody>
  </table>
</div>
<script>
document.addEventListener('alpine:init', () => {
  Alpine.data('tableDemo', () => ({
    data: [{id: 1, label: 'Alpha'}, {id: 2, label: 'Beta'}],
    selected: null,
    select(id) { this.selected = id },
    deleteItem(id) { this.data = this.data.filter(item => item.id !== id) },
    update(id) { const item = this.data.find(i => i.id === id); if (item) item.label += ' (updated)' }
  }));
});
</script>
```

## Dynamic Loops

Here we show how to dynamically generate lots of data and render it efficiently using Alpine. The example uses methods like `buildData()` and `runLots()` to fill the data array, and the UI updates automatically thanks to Alpine reactivity.

```html
<div x-data="loopDemo">
  <button @click="runLots">Generate 1000 Rows</button>
  <button @click="clear">Clear</button>
  <ul>
    <template x-for="item in data" :key="item.id">
      <li>
        <span x-text="item.label"></span>
      </li>
    </template>
  </ul>
</div>
<script>
document.addEventListener('alpine:init', () => {
  Alpine.data('loopDemo', () => ({
    data: [],
    nextId: 1,
    buildData(count = 1000) {
      let adjectives = ['pretty', 'large', 'big'];
      let nouns = ['table', 'chair', 'house'];
      let arr = [];
      for (let i = 0; i < count; i++) {
        arr.push({
          id: this.nextId++,
          label: adjectives[i % adjectives.length] + ' ' + nouns[i % nouns.length]
        });
      }
      return arr;
    },
    runLots() {
      this.data = this.buildData(1000);
    },
    clear() { this.data = [] }
  }));
});
</script>
```

## Reactive Memory Buttons

This snippet demonstrates Alpine's reactivity for toggling button states. The example tracks which "memory slot" is active and toggles its state with a button, updating the UI instantly.

```html
<div x-data="{ memories: [false, false, false] }">
  <template x-for="(on, idx) in memories" :key="idx">
    <button
      :class="{active: on}"
      @click="memories[idx] = !on"
      x-text="on ? 'On' : 'Off'">
    </button>
  </template>
</div>
```

## Mutation Observer Madness

This advanced example uses Alpine.js to react to DOM mutations, "undoing" them in real time. A `MutationObserver` watches for unwanted changes to the DOM and restores the previous state, demonstrating Alpine's integration with low-level browser APIs for creative UI hacks.

```html
<div x-data="mutationWatcher">
  <div id="watched" x-ref="watched">
    <span x-text="text"></span>
  </div>
  <button @click="mutate">Mutate DOM</button>
</div>
<script>
document.addEventListener('alpine:init', () => {
  Alpine.data('mutationWatcher', () => ({
    text: 'Stable Text',
    oldHTML: '',
    mutate() {
      this.$refs.watched.innerHTML = '<b>Corrupted!</b>';
    },
    init() {
      this.oldHTML = this.$refs.watched.innerHTML;
      const observer = new MutationObserver(() => {
        if (this.$refs.watched.innerHTML !== this.oldHTML) {
          this.$refs.watched.innerHTML = this.oldHTML;
        }
      });
      observer.observe(this.$refs.watched, { childList: true, subtree: true });
    }
  }));
});
</script>
```

<!--
Sora Prompt: A decaying archive of UI components built entirely in Alpine.js, styled like a forgotten NASA dashboard from 1994.
Limerick:
An archive once statically plain,
Learned buttons that muttered in vain.
With Alpine in tow,
They juggled the DOM slow—
And corrupted the markup with pain.
-->
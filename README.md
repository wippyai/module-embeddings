<p align="center">
    <a href="https://wippy.ai" target="_blank">
        <picture>
            <source media="(prefers-color-scheme: dark)" srcset="https://github.com/wippyai/.github/blob/main/logo/wippy-text-dark.svg?raw=true">
            <img width="30%" align="center" src="https://github.com/wippyai/.github/blob/main/logo/wippy-text-light.svg?raw=true" alt="Wippy logo">
        </picture>
    </a>
</p>
<h1 align="center">Embeddings Module</h1>
<div align="center">

[![Latest Release](https://img.shields.io/github/v/release/wippyai/module-embeddings?style=flat-square)][releases-page]
[![License](https://img.shields.io/github/license/wippyai/module-embeddings?style=flat-square)](LICENSE)
[![Documentation](https://img.shields.io/badge/Wippy-Documentation-brightgreen.svg?style=flat-square)][wippy-documentation]

</div>

Text embedding library that converts text into vector representations.
Part of the unified LLM interface, supporting multiple providers and models.

## Usage

```lua
local llm = require("llm")

-- Single text
local response = llm.embed("Text to embed", {
    model = "text-embedding-3-large"
})

-- Multiple texts
local texts = {"Text 1", "Text 2"}
local response = llm.embed(texts, {
    model = "text-embedding-3-large",
    dimensions = 1536
})
```

Used for semantic search, document similarity, and applications requiring text vector representations.

[wippy-documentation]: https://docs.wippy.ai
[releases-page]: https://github.com/wippyai/module-embeddings/releases

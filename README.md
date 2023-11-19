# Jupytext.nvim

Seamlessly open [Jupyter Notebooks](http://jupyter.org) as there associated
plain text alternatives. Powered by [jupytext](https://www.github.com/mwouts/jupytext).

`jupytext.nvim` is a lua port of the original
[jupytext.vim](https://www.github.com/goerz/jupytext.vim) with some additional
features and a simpler configuration.

## Installation
`lazy.nvim` example:
```lua
return {
  "GCBallesteros/jupytext.nvim",
  config=true,
}
```



For `jupytext.nvim` to run correctly you will also need to make sure that you
have `jupytext` CLI installed (`pip install jupytext`).

## Configuration

The only configuration parameter available is the jupytext style you want to
use for the plain text version of the files. The default configuration is:

```lua
{
  style = "hydrogen",
}
```

If you need something different pass your own configuration to
`require("jupytext").setup`, e.g.

```lua
require("jupytext").setup({style="light"})

```

## Acknowledgements
This plugin is a lua port of [goerz/jupytext.vim](https://www.github.com/goerz/jupytext.vim) and it wouldn't have existed without it.

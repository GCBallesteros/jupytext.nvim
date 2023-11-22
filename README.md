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
  config = true,
  -- Depending on your nvim distro or config you may need to make the loading not lazy
  -- lazy=false,
}
```


For `jupytext.nvim` to run correctly you will also need to make sure that you
have the `jupytext` CLI installed (`pip install jupytext`).

If `jupytext` is available and yet when you open a notebook you still see a wall
of inscrutable JSON then it may be that `jupytext.nvim` wasn't available due
to lazy loading. The easiest fix is to not lazy load this plugin. For example
if using `lazy.nvim` just set `lazy=false`. This plugin is tiny and will be a
rounding error on your startup time.

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
require("jupytext").setup({ style = "light" })
```

## Acknowledgements
This plugin is a lua port of [goerz/jupytext.vim](https://www.github.com/goerz/jupytext.vim) and it wouldn't have existed without it.

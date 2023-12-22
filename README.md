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

### Simple configuration

The simplest configuration only requires you to decide what plain text
representation you want jupytext to output. The default configuration is:

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

### Configuration for Quarto users

By default we use the `auto` mode of jupytext. This will create a script with
the correct extension for each language. However, users of Quarto will want to
convert the files to Quarto markdown with file extension `qmd`.  The use of the
`auto` mode can be overriden in a per language basis by explicitly declaring
what file extension, jupytext style and Neovim filetype you want. For example,
to use the Quarto file extension and jupytext style with Python you could add
the following to your configuration.

```lua
{
  custom_language_formatting = {
    python = {
      extension = "qmd",
      style = "quarto",
      force_ft = "quarto",
    },
  },
},
```

The `force_ft` option is there to allow you what filetype you want the buffer
to be set to. This is important to get other plugins like
[otter.nvim](https://github.com//otter.nvim) working correctly.


## Acknowledgements
This plugin is a lua port of [goerz/jupytext.vim](https://www.github.com/goerz/jupytext.vim) and it wouldn't have existed without it.

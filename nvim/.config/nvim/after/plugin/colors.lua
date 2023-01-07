require("catppuccin").setup({
    flavour = "mocha", -- latte, frappe, macchiato, mocha
    background = { -- :h background
        light = "latte",
        dark = "mocha",
    },
    transparent_background = true,
    term_colors = false,
    dim_inactive = {
        enabled = false,
        shade = "dark",
        percentage = 0.15,
    },
    no_italic = false, -- Force no italic
    no_bold = false, -- Force no bold
    styles = {
        comments = { "italic" },
        conditionals = { "italic" },
        loops = {},
        functions = {},
        keywords = {},
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
        operators = {},
    },
    color_overrides = {},
    custom_highlights = {},
    integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        telescope = true,
        notify = false,
        mini = false,
        -- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
    },
})

function ColorMeBaby(color)
    color = color or "catpuccin-mocha"

    vim.cmd("set termguicolors")
    -- setup must be called before loading
    vim.cmd.colorscheme "catppuccin-mocha"
    --
    -- Transparency
    vim.cmd [[hi Normal guibg=NONE ctermbg=NONE]]
    vim.cmd [[hi Folded ctermfg=darkgray]]
    vim.cmd [[hi clear CursorLine]]
    vim.cmd [[hi CursorLine guifg=none guibg=black ]]
    vim.cmd [[hi Search guifg=red guibg=none ]]
    vim.cmd [[hi TSConstant  guifg=lightmagenta ]]

    -- for windows
    vim.cmd([[autocmd! ColorScheme * highlight NormalFloat guibg=None]])
    vim.cmd([[autocmd! ColorScheme * highlight FloatBorder guifg=purple guibg=None]])
    vim.cmd([[hi Blamer guifg=lightgray]])	
end 

ColorMeBaby()

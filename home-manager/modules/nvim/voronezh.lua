-- Voronezh colorscheme for Neovim
-- Place at ~/.config/nvim/colors/voronezh.lua
-- Activate with :colorscheme voronezh

vim.cmd('highlight clear')
if vim.fn.exists('syntax_on') then
  vim.cmd('syntax reset')
end

vim.opt.background = 'dark'
vim.g.colors_name = 'voronezh'

local c = {
  base           = '#1C1917',
  surface        = '#262320',
  surface_raised = '#2F2B27',
  border         = '#3D3833',
  text           = '#D6CFC2',
  text_muted     = '#7A7568',
  steel          = '#6B7278',
  rust           = '#A84826',
  brick          = '#7A2E1F',
  ochre          = '#B89650',
  warning        = '#C8302E',
  success        = '#7A8066',
}

local set = vim.api.nvim_set_hl

-- Editor base
set(0, 'Normal',        { fg = c.text, bg = c.base })
set(0, 'NormalFloat',   { fg = c.text, bg = c.surface })
set(0, 'NormalNC',      { fg = c.text, bg = c.base })
set(0, 'EndOfBuffer',   { fg = c.border, bg = c.base })
set(0, 'LineNr',        { fg = c.text_muted })
set(0, 'CursorLine',    { bg = c.surface })
set(0, 'CursorLineNr',  { fg = c.rust, bold = true })
set(0, 'SignColumn',    { bg = c.base })
set(0, 'Folded',        { fg = c.text_muted, bg = c.surface })
set(0, 'FoldColumn',    { fg = c.text_muted, bg = c.base })
set(0, 'ColorColumn',   { bg = c.surface })
set(0, 'VertSplit',     { fg = c.border })
set(0, 'WinSeparator',  { fg = c.border })

-- Selection and search
set(0, 'Visual',        { bg = c.surface_raised })
set(0, 'VisualNOS',     { bg = c.surface_raised })
set(0, 'Search',        { fg = c.base, bg = c.ochre })
set(0, 'IncSearch',     { fg = c.base, bg = c.rust })
set(0, 'CurSearch',     { fg = c.base, bg = c.rust })
set(0, 'MatchParen',    { fg = c.rust, bold = true })

-- Popup menu (completion)
set(0, 'Pmenu',         { fg = c.text, bg = c.surface })
set(0, 'PmenuSel',      { fg = c.text, bg = c.surface_raised, bold = true })
set(0, 'PmenuSbar',     { bg = c.surface })
set(0, 'PmenuThumb',    { bg = c.rust })

-- Status line
set(0, 'StatusLine',    { fg = c.text, bg = c.surface })
set(0, 'StatusLineNC',  { fg = c.text_muted, bg = c.surface })

-- Tab line
set(0, 'TabLine',       { fg = c.text_muted, bg = c.surface })
set(0, 'TabLineFill',   { bg = c.surface })
set(0, 'TabLineSel',    { fg = c.text, bg = c.base, bold = true })

-- Messages
set(0, 'ErrorMsg',      { fg = c.warning })
set(0, 'WarningMsg',    { fg = c.ochre })
set(0, 'MoreMsg',       { fg = c.rust })
set(0, 'Question',      { fg = c.ochre })

-- Syntax highlighting
set(0, 'Comment',       { fg = c.text_muted, italic = true })
set(0, 'Constant',      { fg = c.ochre })
set(0, 'String',        { fg = c.steel })
set(0, 'Character',     { fg = c.steel })
set(0, 'Number',        { fg = c.ochre })
set(0, 'Boolean',       { fg = c.ochre })
set(0, 'Float',         { fg = c.ochre })

set(0, 'Identifier',    { fg = c.text })
set(0, 'Function',      { fg = c.ochre })

set(0, 'Statement',     { fg = c.rust })
set(0, 'Conditional',   { fg = c.rust })
set(0, 'Repeat',        { fg = c.rust })
set(0, 'Label',         { fg = c.rust })
set(0, 'Operator',      { fg = c.text })
set(0, 'Keyword',       { fg = c.rust })
set(0, 'Exception',     { fg = c.warning })

set(0, 'PreProc',       { fg = c.brick })
set(0, 'Include',       { fg = c.brick })
set(0, 'Define',        { fg = c.brick })
set(0, 'Macro',         { fg = c.brick })
set(0, 'PreCondit',     { fg = c.brick })

set(0, 'Type',          { fg = c.text, bold = true })
set(0, 'StorageClass',  { fg = c.rust })
set(0, 'Structure',     { fg = c.text, bold = true })
set(0, 'Typedef',       { fg = c.text, bold = true })

set(0, 'Special',       { fg = c.rust })
set(0, 'SpecialChar',   { fg = c.rust })
set(0, 'Tag',           { fg = c.rust })
set(0, 'Delimiter',     { fg = c.text_muted })
set(0, 'SpecialComment',{ fg = c.text_muted, italic = true })
set(0, 'Debug',         { fg = c.warning })

set(0, 'Underlined',    { fg = c.rust, underline = true })
set(0, 'Ignore',        { fg = c.text_muted })
set(0, 'Error',         { fg = c.warning })
set(0, 'Todo',          { fg = c.base, bg = c.ochre, bold = true })

-- Diffs
set(0, 'DiffAdd',       { fg = c.text, bg = '#2A3D28' })
set(0, 'DiffChange',    { fg = c.text, bg = '#3D3428' })
set(0, 'DiffDelete',    { fg = c.text, bg = '#4A2024' })
set(0, 'DiffText',      { fg = c.base, bg = c.ochre })

-- Diagnostics (LSP)
set(0, 'DiagnosticError',       { fg = c.warning })
set(0, 'DiagnosticWarn',        { fg = c.ochre })
set(0, 'DiagnosticInfo',        { fg = c.steel })
set(0, 'DiagnosticHint',        { fg = c.text_muted })
set(0, 'DiagnosticOk',          { fg = c.success })
set(0, 'DiagnosticUnderlineError', { undercurl = true, sp = c.warning })
set(0, 'DiagnosticUnderlineWarn',  { undercurl = true, sp = c.ochre })
set(0, 'DiagnosticUnderlineInfo',  { undercurl = true, sp = c.steel })
set(0, 'DiagnosticUnderlineHint',  { undercurl = true, sp = c.text_muted })

-- Treesitter (neovim 0.8+)
set(0, '@variable',         { fg = c.text })
set(0, '@variable.builtin', { fg = c.rust, italic = true })
set(0, '@parameter',        { fg = c.text })
set(0, '@field',            { fg = c.text })
set(0, '@property',         { fg = c.text })
set(0, '@function',         { fg = c.ochre })
set(0, '@function.call',    { fg = c.ochre })
set(0, '@function.builtin', { fg = c.ochre, italic = true })
set(0, '@method',           { fg = c.ochre })
set(0, '@constructor',      { fg = c.text, bold = true })
set(0, '@keyword',          { fg = c.rust })
set(0, '@keyword.function', { fg = c.rust })
set(0, '@keyword.return',   { fg = c.rust, bold = true })
set(0, '@conditional',      { fg = c.rust })
set(0, '@repeat',           { fg = c.rust })
set(0, '@string',           { fg = c.steel })
set(0, '@string.escape',    { fg = c.ochre })
set(0, '@number',           { fg = c.ochre })
set(0, '@boolean',          { fg = c.ochre })
set(0, '@comment',          { fg = c.text_muted, italic = true })
set(0, '@type',             { fg = c.text, bold = true })
set(0, '@type.builtin',     { fg = c.text, bold = true })
set(0, '@namespace',        { fg = c.brick })
set(0, '@punctuation',      { fg = c.text_muted })
set(0, '@tag',              { fg = c.rust })
set(0, '@tag.attribute',    { fg = c.ochre })

-- Git gutter signs
set(0, 'GitSignsAdd',    { fg = c.success })
set(0, 'GitSignsChange', { fg = c.ochre })
set(0, 'GitSignsDelete', { fg = c.warning })
set(0, 'DiffAdded',      { fg = c.success })
set(0, 'DiffRemoved',    { fg = c.warning })

-- Telescope (if used)
set(0, 'TelescopeBorder',         { fg = c.rust, bg = c.base })
set(0, 'TelescopePromptBorder',   { fg = c.rust, bg = c.surface })
set(0, 'TelescopePromptTitle',    { fg = c.rust, bg = c.surface })
set(0, 'TelescopeSelection',      { fg = c.text, bg = c.surface_raised })
set(0, 'TelescopeSelectionCaret', { fg = c.rust, bg = c.surface_raised })
set(0, 'TelescopeMatching',       { fg = c.ochre, bold = true })

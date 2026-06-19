{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # 1. Translate Plugin calls (replaces vim-plug)
    plugins = with pkgs.vimPlugins; [
      vimtex
    ];

    # 2. Translate init.vim settings
    extraLuaConfig = ''
      -- Basic Vim Settings
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.syntax = 'on'
      
      -- VimTeX Settings
      vim.g.vimtex_view_method = 'zathura'
      vim.g.vimtex_compiler_method = 'latexmk'
      vim.g.vimtex_quickfix_mode = 0
      
      -- Spellcheck
      vim.api.nvim_create_autocmd("FileType", {
        pattern = {"tex", "latex", "markdown"},
        callback = function()
          vim.opt_local.spell = true
          vim.opt_local.spelllang = 'en_us'
        end
      })

      -- Load the Voronezh colorscheme
      vim.cmd('colorscheme voronezh')
    '';
  };

  # 3. Handle the custom colorscheme file
  # Instead of managing a folder, we inject the specific file into the nvim runtime path
  xdg.configFile."nvim/colors/voronezh.lua".source = ./voronezh.lua;
}

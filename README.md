# Dotfiles

## Tools

- nvim/vscode (PDE/IDE)
  - I use LazyVim as an nvim distro and customize it a bit more to my liking
- VS Code (IDE)
- tmux (session manager)
- Aurora by Universal Blue: OS
- OBS
- stow (dotfiles management)
- starship (beautiful prompt)
- JetBrainsMono Nerd Font (font)
- python (goto coding language - nvim is setup primarily as a python IDE)
- copier (for quick templating posts for my blog or other reusable files)
- direnv (automatically source python virtual environments via .envrc)
- visidata (terminal-based data viewer)
- zsh (shell)
- [fancy-motd](https://github.com/bcyran/fancy-motd)
- [skm](https://github.com/TimothyYe/skm) for ssh key management

## Stow

Use `stow` since it's awesome!

For a quick intro check out [ThePrimeagen's YT video](https://www.youtube.com/watch?v=tkUllCAGs3c)

## Nvim

I use [The freaking amazing LazyVim by @Folke](https://www.lazyvim.org/) as my vim experience. Checkout the getting started and feel free to rip my config.

Setup looks like:

1. Install [requirements](https://www.lazyvim.org/#%EF%B8%8F-requirements)
2. Start nvim
3. profit

## Notes

- If starship is showing your environment twice set the following:
  `conda config --set changeps1 false` and then resource `zsh`
- For polybar colorizing icons I just have polybar render the output through a font like this `content = "%{T4}%{F#5d3fd3}省%{F-}%{T-}"` Where a font is chosen (T4) then the color I want follows the `F#` with the icon placed after the brace. The font size can be huge for some icons depending on where they come from

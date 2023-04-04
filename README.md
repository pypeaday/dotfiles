# Pypeaday's Dotfiles

I keep dotfiles here that I share between my work laptop and home computers.
There is a lot of overlap but also some key distinctions -> see notes on each tool

## Tools

- nvim (PDE/IDE)
- I use LazyVim as an nvim distro and customize it a bit more to my liking
- tmux (session manager)
- i3-gaps (work: Tiling window manager)
- pop_os! 22.04 (home: OS and DE)
- picom (work: compositor for i3 )
- OBS (streaming/virtual cam, note: I use the `snap` since virtual-cam support seems broken in the .deb and flatpak on Pop_OS! 22.04... see [install instructions](https://snapcraft.io/obs-studio))
- polybar (work: productivity tool bar)
- stow (dotfiles management)
- starship (beautiful prompt)
- JetBrainsMono Nerd Font (font)
- kitty (terminal emulator)
- python (goto coding language - nvim is setup primarily as a python IDE)
- copier (for quick templating posts for my blog or other reusable files)
- direnv (automatically source python virtual environments via .envrc)
- rofi (work: app launcher)
- visidata (terminal-based data viewer)
- zsh (shell)
- [fancy-motd](https://github.com/bcyran/fancy-motd)

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

### Notes for my older Ubuntu 18 machine

PICOM

    - For transparency with default terminal in i3
       - Need to install picom (on older Ubuntu I had to build from source: https://github.com/jonaburg/picom)
       - https://www.linuxfordevices.com/tutorials/linux/picom

POLYBAR

    - install fontawesome with `apt install fonts-font-awesome`
    - build from source here: https://github.com/polybar/polybar

OBS

    - `sudo modprobe v4l2loopback video_nr=10 card_label="OBS Video Source" exclusive_caps=1`
    - That command is needed if the virtual cam support isn't immediately availble with obs-studio. I need this for work since we're on older Ubuntu with a locked down set of repositories to go to

I3-GAPS

    I had to install from source - see here: https://lottalinuxlinks.com/how-to-build-and-install-i3-gaps-on-debian/

## TODOs

- setup snippit for polybar icon color

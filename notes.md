# My Notes

## copier

`pipx install --pip-args '\--pre' copier`  # make sure you're greater than v6
maybe need `pipx inject copier "MarkupSafe<2.1.0"`

## Presenting 
* Customizing vim with vimrc
* File and Nav remaps
* Marks

## vimrc
* vim -> vimrc
* neovim -> .config/nvim/init.vim
* whatever we `:set` in vim can go into vimrc for persisting settings across sessions
* settings he reviews:
* * number relnumber
* * colorscheme
* * 

## Remaps
* mapleader - mine is space like Prime
* * first letter is vim mode
* inoremap, vnoremap, nnoremap
* * `nore` is "no recursive" meaning the remap doesn't do other remaps
* * `map` is the map
* * `nnoremap <leader> pv :Vex<CR>` is a command Prime did to bring up the default file tree view with `pv` or "project view"
* Keep remaps at 3 keys or less
* Prime says to always use a leader key to avoid annoying artifacts
* * example is remapping `pv` like above wtihout the leader key will make every "paste" command hang for a few millliseconds because vim is waiting for you to do the remap before executing the default `p` behavior

## Marks
* `m <Capital Letter>` will create a mark that spans the vim buffer (global level)
* `m <lower case letter>` will create a mark that is only for that file (file level)
* jump to a mark with `'<letter>`

## Presenting Session 2
* My First Vim Plugin
* What Makes a Good Plugin

## Registers
yank this into the b register with shift+v "b y
Can I paste from the register?
yes, with "bp

* whatever we `:set` in vim can go into vimrc for persisting settings across sessions

* Power of this is that you can edit macros since they get saved to the register - just find the register with the macro, paste it in a file, edit, and yank it into a new register, then call the macro with @ and whatever register you yanked to

## My First Vim Plugin
* Prime write one in VimL
    ```
    fun! Scrtch(cmd)
        new
        setlocal nobuflisted buftype=nofile bufhidden=delete
        let output = call systemlist(a:cmd)

        call append(0, l:output)
    endfun
    ```
    * Vim become about knowing what you want to do rather than thinking about how to do it
## What Makes a Good Plugin
* If you have to memorize bunch of things that aren't a simple set of keystrokes that eventully become second nature than there is something wrong with the plugin


## v4l2loopback

Sometimes at work the module isn't found right "module v4l2loopback not found in directory <kernel stufff>"
my fix is to go to ~//third-party/v4l2loopback anad run:
v4l2loopback  🌱 main on ☁️  (us-east-1)
❯ make clean
rm -f *~
rm -f Module.symvers Module.markers modules.order
make -C /lib/modules/`uname -r`/build M=/home/u_paynen3/third-party/v4l2loopback clean
make[1]: Entering directory '/usr/src/linux-headers-5.4.0-94-generic'
make[1]: Leaving directory '/usr/src/linux-headers-5.4.0-94-generic'
make -C utils clean
make[1]: Entering directory '/home/u_paynen3/third-party/v4l2loopback/utils'
rm v4l2loopback-ctl
make[1]: Leaving directory '/home/u_paynen3/third-party/v4l2loopback/utils'


v4l2loopback  🌱 main on ☁️  (us-east-1)
❯ sudo make 


v4l2loopback  🌱 main on ☁️  (us-east-1)
❯ sudo make install

v4l2loopback  🌱 main on ☁️  (us-east-1)
❯ sudo depmod -a

v4l2loopback  🌱 main on ☁️  (us-east-1)  took 26s
❯ sudo modprobe v4l2loopback video_nr=10 card_label="OBS Video Source" exclusive_caps=1


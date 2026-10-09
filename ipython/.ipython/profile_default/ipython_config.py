c.InteractiveShellApp.extensions = ["autoreload"]
c.InteractiveShellApp.exec_lines = ["%autoreload 2"]
c.InteractiveShellApp.extensions.append("pyflyby")
# c.InteractiveShellApp.exec_lines.append(
#     'print("Warning: disable autoreload in ipython_config.py to improve performance.")'
# )
c.TerminalInteractiveShell.banner1 = ""
# c.TerminalInteractiveShell.editing_mode = "vi"
##
## Basic color scheme that will be modified
##

colorLabel = "Linux"
c.InteractiveShell.colors = colorLabel


import importlib


def activate_extension(extension):
    try:
        mod = importlib.import_module(extension)
        getattr(mod, "load_ipython_extension")
        c.InteractiveShellApp.extensions.append(extension)
    except ModuleNotFoundError:
        "extension is not installed"
    except AttributeError:
        "extension does not have a 'load_ipython_extension' function"


extensions = ["rich", "markata", "pyflyby"]
for extension in extensions:
    activate_extension(extension)


from pygments.token import (
    Comment,
    Error,
    Generic,
    Keyword,
    Name,
    Number,
    Operator,
    String,
    Token,
    Whitespace,
)

# starting to try to match vim-airline and my tmux
black = "#282c34"  # gui_black
grey = "#484e5a"  # light gray
cyan = "#83DCC8"  # gui_cyan
cyan_offset = "#68b0a0"  # gui_cyan_offset
purple = "#c792ea"  # gui_purple
green = "#afd75f"  # gui_green
blue = "#81aaff"  # gui_blue

red = "#E06C75"
yellow = "#E5C07B"
magenta = "#C678DD"

white = "#ffffff"


c.TerminalInteractiveShell.highlighting_style_overrides = {
    ## Standard Pygments tokens (are all used by IPython ?)
    Whitespace: grey,
    Comment: f"italic {green}",
    Comment.Preproc: "noitalic",
    # Comment.Special: f"noitalic bold",
    Keyword: f"bold {magenta}",
    Keyword.Pseudo: "nobold",
    Keyword.Type: f"bold {green}",
    Operator: grey,
    Operator.Word: f"bold {magenta}",
    Name.Builtin: f"{cyan}",
    Name.Function: purple,
    Name.Class: yellow,
    Name.Namespace: f"bold {blue}",
    Name.Exception: f"bold {red}",
    Name.Variable: yellow,
    Name.Constant: red,
    Name.Label: red,
    Name.Entity: f"bold {grey}",
    Name.Attribute: red,
    Name.Tag: f"bold {green}",
    Name.Decorator: magenta,
    String: red,
    # String.Doc: f"italic",
    String.Interpol: f"bold {red}",
    String.Escape: f"bold {yellow}",
    String.Regex: red,
    String.Symbol: yellow,
    String.Other: green,
    Number: grey,
    Generic.Heading: cyan,
    Generic.Subheading: f"bold {purple}",
    Generic.Deleted: red,
    Generic.Inserted: green,
    Generic.Error: red,
    Generic.Emph: "italic",
    Generic.Strong: "bold",
    Generic.Prompt: f"bold {blue}",
    Generic.Output: grey,
    Generic.Traceback: blue,
    Error: f"border:{red}",
    Token.Number: f"{white}",
    Token.Operator: "noinherit",
    Token.String: green,
    Token.Name.Function: cyan,
    Token.Name.Class: f"{cyan_offset}",
    # Token.
    # Token.Name.Namespace: f"bold {blue}",
    Token.Name.Field: yellow,
    Token.Prompt: f"{grey} bold",
    Token.PromptNum: f"{grey} bold",
    Token.OutPrompt: f"{blue}",
    Token.OutPromptNum: f"{cyan} bold",
}

## Autoformatter to reformat Terminal code. Can be `'black'` or `None`
#  Default: None
c.TerminalInteractiveShell.autoformatter = "black"

## Use 24bit colors instead of 256 colors in prompt highlighting. If your
#  terminal supports true color, the following command should print 'TRUECOLOR'
#  in orange: printf "\x1b[38;2;255;100;0mTRUECOLOR\x1b[0m\n"
#  Default: False
c.TerminalInteractiveShell.true_color = True

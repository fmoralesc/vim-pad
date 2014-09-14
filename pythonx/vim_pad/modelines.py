html_style = ("<!-- ", " -->")
vim_style = ('" ', '')
hash_style = ("# ", '')

comment_style_map = {
        "markdown": html_style,
        "pandoc": html_style,
        "textile": html_style,
        "vo_base": html_style,
        "quicktask": hash_style
        }


def format_modeline(filetype):
    try:
        style = comment_style_map[filetype]
    except KeyError:
        style = vim_style
    return style[0] + "vim: set ft=" + filetype + ":" + style[1]


# CineNvim

# CineNvim 🎬

**CineNvim** is a highly specialized Neovim configuration designed specifically for screenwriters. It turns your terminal into a distraction-free, fully-featured screenplay studio using the [Fountain](https://fountain.io/) plain-text markup language.

**⚠️ Note:** This is *not* a standalone application. It is a single `init.lua` file that you can use as your Neovim configuration.

I built this because I wanted a fast, terminal-based alternative to heavy screenwriting software, without sacrificing professional formatting.

## Features

- **Live Screenplay Rendering:** Dynamically adjusts text widths and margins as you type (Dialogue, Characters, Parentheticals, and Action lines format automatically).
- **Native Character Autocomplete:** The engine scrapes your document for character names. Just start typing a character's name in caps and press `<Enter>` to autocomplete.
- **True Typewriter Mode:** Keeps your cursor perfectly centered on the screen while you write.
- **Zen Mode:** Strips away all Neovim UI elements (line numbers, status bars) for pure focus.
- **File Management:** Integrated `oil.nvim` to browse and manage your script files like standard text buffers.
- **One-Keystroke PDF Export:** Compiles your `.fountain` file into a perfectly formatted, industry-standard PDF.

## Prerequisites

To use this setup, you will need:

1. **Neovim** (v0.9.0 or higher)
2. **Git** (to automatically download the plugins)
3. **[afterwriting](https://www.google.com/search?q=https://github.com/ifrost/afterwriting-labs/blob/master/docs/clients.md)** (Optional, but required if you want to export your scripts to PDF).

## Installation

Since this is just a configuration file, installation is as simple as dropping it into your Neovim config folder.

1. Back up your existing Neovim config (if you have one):

   Bash

   ```
   mv ~/.config/nvim ~/.config/nvim.bak
   ```

2. Create the config directory:

   Bash

   ```
   mkdir -p ~/.config/nvim
   ```

3. Copy the `init.lua` from this repository into that folder:

   Bash

   ```
   curl -o ~/.config/nvim/init.lua https://raw.githubusercontent.com/BeetleBot/CineNvim/main/init.lua
   ```

Open Neovim. It will automatically download the necessary plugins (Lazy.nvim, Catppuccin, ZenMode, Oil, etc.) on the first run.

## Usage & Keymaps

Save your files with the `.fountain` extension to trigger the screenplay engine.

| Command / Shortcut | Action                                                       |
| ------------------ | ------------------------------------------------------------ |
| **`-`** (minus)    | Open the file picker (`oil.nvim`) to browse your scripts.    |
| **`<Space> z`**    | Toggle Zen Mode (Distraction-free writing).                  |
| **`<Space> tw`**   | Toggle Typewriter Mode (Centers cursor on screen).           |
| **`<Space> f`**    | Fix paragraph formatting/wrapping for the current block.     |
| **`<Space> p`**    | Export the current file to PDF (Requires `afterwriting` CLI). |

### Title Page Generation

You can generate your title page metadata right from the Neovim command line. Run these commands anywhere in your document, and they will safely inject the formatting at the very top of your script:

- `:FountainTitle [Your Title]`
- `:FountainAuthor [Your Name]`
- `:FountainCredits [Written by, Story by, etc.]`
- `:FountainNotes [Draft info, dates, etc.]`
- `:FountainContact [Email, Phone, etc.]`

## License

MIT. Feel free to fork it, tweak it, and write your masterpiece.
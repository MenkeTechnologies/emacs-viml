```
███████╗███╗   ███╗ █████╗  ██████╗███████╗      ██╗   ██╗██╗███╗   ███╗██╗
██╔════╝████╗ ████║██╔══██╗██╔════╝██╔════╝      ██║   ██║██║████╗ ████║██║
█████╗  ██╔████╔██║███████║██║     ███████╗█████╗██║   ██║██║██╔████╔██║██║
██╔══╝  ██║╚██╔╝██║██╔══██║██║     ╚════██║╚════╝╚██╗ ██╔╝██║██║╚██╔╝██║██║
███████╗██║ ╚═╝ ██║██║  ██║╚██████╗███████║       ╚████╔╝ ██║██║ ╚═╝ ██║███████╗
╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝        ╚═══╝  ╚═╝╚═╝     ╚═╝╚══════╝
```

[![CI](https://github.com/MenkeTechnologies/emacs-viml/actions/workflows/ci.yml/badge.svg)](https://github.com/MenkeTechnologies/emacs-viml/actions/workflows/ci.yml)
[![Docs](https://img.shields.io/badge/docs-05d9e8.svg)](https://menketechnologies.github.io/emacs-viml/)
[![Report](https://img.shields.io/badge/report-ff2a6d.svg)](https://menketechnologies.github.io/emacs-viml/report.html)
[![Emacs](https://img.shields.io/badge/emacs-27.1%2B-39ff14.svg)](https://www.gnu.org/software/emacs/)
[![License: MIT](https://img.shields.io/badge/License-MIT-d300c5.svg)](https://opensource.org/licenses/MIT)

### `[EMACS MAJOR MODE // NEON FONT-LOCK // SCOPE VARS // RUN + LSP]`

> *"Open a `.vim`. Functions, scopes, `v:` specials, and the whole ex-command surface light up."*

Emacs major mode (`vimlrs-mode`) for **VimL (Vimscript)**, targeting the **[vimlrs](https://github.com/MenkeTechnologies/vimlrs)** standalone interpreter (a Rust port of Neovim's eval engine on fusevm). Font-lock for statement keywords, ex commands, scope-namespaced variables (`g:` `s:` `b:` `v:` …), special `v:` variables, built-in functions, and function definitions; filetype detection; block-keyword-aware indentation; run a buffer through `vimlrs`; eldoc + completion for builtins; and LSP via `vimlrs --lsp` (eglot + lsp-mode). Named `vimlrs-mode` so it does not clash with Emacs' built-in `vimrc-mode`.

### [`Read the Docs`](https://menketechnologies.github.io/emacs-viml/) &middot; [`Engineering Report`](https://menketechnologies.github.io/emacs-viml/report.html) · [`vimlrs`](https://github.com/MenkeTechnologies/vimlrs) · [`vim-vimlrs`](https://github.com/MenkeTechnologies/vim-vimlrs) · [`vscode-vimlrs`](https://github.com/MenkeTechnologies/vscode-vimlrs)

---

## [0x00] OVERVIEW

**emacs-viml** is the Emacs major mode for **VimL (Vimscript)** (the `vimlrs` engine). It provides:

- **Filetype detection** — `*.vim` files plus the `vimrc` / `gvimrc` / `exrc` / `init.vim` family (`auto-mode-alist`), and `vim` / `nvim` / `vimlrs` shebangs (`interpreter-mode-alist`).
- **Syntax highlighting** — font-lock for VimL statement keywords, common ex commands, scope-namespaced variables (`g:` `s:` `b:` `w:` `t:` `l:` `a:` `v:`), special `v:` variables (`v:true`, `v:count`, `v:val`), built-in functions, function definitions, single/double-quoted strings, and command-position `"` comments.
- **Indentation** — block-keyword-aware `indent-line-function` (deeper after `if`/`while`/`for`/`function`/`try`/`augroup`; dedent on `end*`/`else`/`elseif`/`catch`/`finally`).
- **Run** — `vimlrs-run-buffer` (`C-c C-c`) runs the buffer through `vimlrs` via `compile`.
- **eldoc + completion** — one-line signatures and `completion-at-point` for VimL builtin functions.
- **Language server** — `vimlrs --lsp` via **eglot** (built in since Emacs 29) and **lsp-mode**.

`vimlrs` ports a fixed subset of Vim's builtin surface, so the keyword / command / function lists are plain `regexp-opt` lists in `vimlrs-mode.el` — no generated hash-table stdlib is needed (that machinery only exists in the sibling `emacs-stryke` because stryke's ~10,450 builtins overflow Emacs' regexp compiler). Builtin-function signatures for eldoc / completion live in `vimlrs-stdlib.el`, authored from the ported subset of Vim's `funcs.c` table.

VimL's classic `"` ambiguity (comment in command position, string in expression position) is resolved with a `syntax-propertize` rule: `"` is a string quote in the syntax table, and the rule re-marks the command-position `"` (line start, or after `|`) as a comment.

`vimlrs --lsp` is launched with **only** `--lsp` — an appended `--stdio` is rejected by the binary, so neither client is configured to add one.

Created by **[MenkeTechnologies](https://github.com/MenkeTechnologies)**.

---

## [0x01] FEATURE MATRIX

| Capability | Status |
|---|---|
| Filetype detection — `*.vim` | **Implemented** — `auto-mode-alist` |
| Filetype detection — vimrc/gvimrc/exrc/init.vim | **Implemented** — `auto-mode-alist` |
| Filetype detection — shebang | **Implemented** — `interpreter-mode-alist` (`vim`, `nvim`, `vimlrs`) |
| Syntax highlighting | **Implemented** — font-lock for keywords, ex commands, scope/special vars, builtins, function defs |
| Comments | **Implemented** — command-position `"` via `syntax-propertize` |
| Strings | **Implemented** — single + double-quoted via syntax table |
| Scope variables | **Implemented** — `vimlrs-scope-var-face` for `g:`/`s:`/`v:`… |
| Special `v:` variables | **Implemented** — `vimlrs-special-var-face` |
| Indentation | **Implemented** — block-keyword-aware `vimlrs-indent-line` |
| Run buffer | **Implemented** — `vimlrs-run-buffer` (`C-c C-c`) via `compile` |
| eldoc | **Implemented** — builtin-function signatures |
| Completion | **Implemented** — `completion-at-point` over builtin functions |
| Language server (eglot) | **Implemented** — `vimlrs --lsp` |
| Language server (lsp-mode) | **Implemented** — registered client |
| Config | `vimlrs-executable`, `vimlrs-indent-offset` |

> The `vimlrs` binary must be on `$PATH` to run buffers and for the language server. Build **[vimlrs](https://github.com/MenkeTechnologies/vimlrs)** (`cargo install --path .`).

---

## [0x02] INSTALL

### Manual

```elisp
;; clone, then:
(add-to-list 'load-path "/path/to/emacs-viml")
(require 'vimlrs-mode)
```

### use-package + built-in VC

```elisp
(use-package vimlrs-mode
  :mode "\\.vim\\'"
  :vc (:url "https://github.com/MenkeTechnologies/emacs-viml"))
```

Open any `.vim` file — it lights up. Press `C-c C-c` to run it through `vimlrs`. With eglot, run `M-x eglot` to start the language server (or `(add-hook 'vimlrs-mode-hook #'eglot-ensure)`).

---

## [0x03] SYNTAX // FACES

| Token group | Face |
|---|---|
| Statement keywords (`if` `function` `for` `while` `try` `let` `call` `echo`) | `font-lock-keyword-face` |
| Ex commands (`set` `autocmd` `augroup` `highlight` `map` `source`) | `font-lock-keyword-face` |
| Scope variables (`g:` `s:` `b:` `w:` `t:` `l:` `a:` `v:`) | `vimlrs-scope-var-face` |
| Special `v:` variables (`v:true` `v:count` `v:val` `v:key`) | `vimlrs-special-var-face` |
| Built-in functions (`len` `split` `substitute` `printf` `has_key`) | `font-lock-builtin-face` |
| Function definitions | `font-lock-function-name-face` |
| Strings / `"` comments | via syntax table + `syntax-propertize` |

---

## [0x04] RUN

`vimlrs-run-buffer` (bound to `C-c C-c`) runs the current buffer through `vimlrs FILE` using Emacs' `compile`, so output, errors (`E121: Undefined variable: foo`-style messages), and `next-error` navigation land in the `*compilation*` buffer. The file is passed **positionally** — `vimlrs` takes the script as an argument, not behind a `-f` flag. The executable is `vimlrs-executable` (default `"vimlrs"`).

---

## [0x05] LANGUAGE SERVER

`vimlrs-mode` registers `vimlrs --lsp` for both clients (lazily, so neither is a hard dependency):

- **eglot** (Emacs 29+): `M-x eglot` in a `.vim` buffer.
- **lsp-mode**: `M-x lsp` (language id `vim`).

The executable is `vimlrs-executable` (default `"vimlrs"`); change it for a custom path. The server is launched with `--lsp` only — no `--stdio` is appended (the binary rejects it).

---

## [0x06] LAYOUT

```
emacs-viml/
├── vimlrs-mode.el          # major mode: syntax table, font-lock, indent, run, LSP, eldoc, completion
├── vimlrs-stdlib.el        # builtin-function signatures (eldoc + completion)
├── scripts/face-test.el    # fontifies a sample and asserts faces
├── tests/face-test.sh      # byte-compile + face assertions wrapper
└── tests/*.sh              # README / docs / workflow validators
```

---

## [0x07] LICENSE

MIT © **[MenkeTechnologies](https://github.com/MenkeTechnologies)**

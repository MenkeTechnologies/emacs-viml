;;; vimlrs-mode.el --- Major mode for the VimL (Vimscript) language (vimlrs) -*- lexical-binding: t; -*-

;; Copyright (c) 2026 MenkeTechnologies

;; Author: MenkeTechnologies
;; URL: https://github.com/MenkeTechnologies/emacs-viml
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: languages, vim

;; This file is not part of GNU Emacs.

;;; Commentary:

;; A major mode for VimL (Vimscript), targeting the `vimlrs' standalone
;; interpreter (a Rust port of Neovim's eval engine, on fusevm).  Named
;; `vimlrs-mode' so it does not clash with Emacs' built-in `vimrc-mode'
;; or third-party `vim-mode' packages.  Provides:
;;
;;   - filetype detection for `*.vim' files, the vimrc/gvimrc/exrc
;;     family, and vim / nvim / vimlrs shebangs
;;   - syntax highlighting: statement keywords, common ex commands,
;;     scope-namespaced variables (g: s: b: w: t: l: a: v:), special
;;     `v:' variables, built-in functions, function definitions,
;;     strings, and command-position `"' comments
;;   - block-keyword-aware indentation
;;   - run the buffer through `vimlrs' (`vimlrs-run-buffer', C-c C-c)
;;   - language-server integration via `vimlrs --lsp' (eglot + lsp-mode)
;;   - eldoc + completion-at-point for VimL builtin functions
;;
;; `vimlrs' ports only a fixed subset of Vim's builtin surface (the
;; keyword / command / function lists below), so those lists are plain
;; `regexp-opt' alternations in this file — well under Emacs' regexp-size
;; limit, so no generated hash-table stdlib is needed.  Builtin-function
;; signatures used for eldoc / completion live in `vimlrs-stdlib.el'.
;;
;; The classic VimL ambiguity is `"': in command position (line start,
;; or just after `|') it begins a comment to end of line; in expression
;; position it is a double-quoted string.  Emacs' syntax table cannot
;; make one character both a string quote and a comment starter, so `"'
;; is a string quote in the table and a `syntax-propertize' rule re-marks
;; the command-position ones as comments.

;;; Code:

(require 'vimlrs-stdlib)

;; Optional integrations — referenced only inside `with-eval-after-load' blocks,
;; declared here so the byte-compiler stays quiet when they are absent.
(defvar eglot-server-programs)
(defvar lsp-language-id-configuration)
(declare-function make-lsp-client "lsp-mode")
(declare-function lsp-register-client "lsp-mode")
(declare-function lsp-stdio-connection "lsp-mode")
(declare-function lsp-activate-on "lsp-mode")

(defgroup vimlrs nil
  "Major mode for the VimL (Vimscript) language (vimlrs)."
  :group 'languages
  :prefix "vimlrs-")

(defcustom vimlrs-executable "vimlrs"
  "Path to the vimlrs executable, used to run buffers and for the language server."
  :type 'string
  :group 'vimlrs)

(defcustom vimlrs-indent-offset 2
  "Number of spaces per indentation level in `vimlrs-mode'."
  :type 'integer
  :group 'vimlrs)

(defface vimlrs-scope-var-face
  '((t :inherit font-lock-variable-name-face :weight bold))
  "Face for VimL scope-namespaced variables (g:, s:, b:, w:, t:, l:, a:, v:...)."
  :group 'vimlrs)

(defface vimlrs-special-var-face
  '((t :inherit font-lock-builtin-face :weight bold))
  "Face for VimL special `v:' variables (v:true, v:count, v:val, ...)."
  :group 'vimlrs)

;;; Keyword categories.  vimlrs ports a fixed subset of Vim's surface, so
;;; plain `regexp-opt' lists stay well under Emacs' regexp-size limit.

(defconst vimlrs--statement-keywords
  '("if" "elseif" "else" "endif" "while" "endwhile" "for" "endfor" "in"
    "function" "endfunction" "return" "break" "continue" "try" "catch"
    "finally" "endtry" "throw" "let" "unlet" "const" "lockvar" "unlockvar"
    "call" "eval" "execute" "echo" "echon" "echohl" "echomsg" "echoerr"
    "echowindow" "finish")
  "VimL statement keywords and control-flow introducers.")

(defconst vimlrs--ex-commands
  '("source" "runtime" "normal" "redir" "silent" "verbose" "set" "setlocal"
    "setglobal" "command" "delcommand" "autocmd" "augroup" "highlight"
    "syntax" "map" "nmap" "imap" "vmap" "xmap" "noremap" "nnoremap"
    "inoremap" "vnoremap" "xnoremap" "cnoremap" "abbreviate" "sign" "sleep")
  "Common VimL ex commands.")

(defconst vimlrs--special-vars
  '("v:true" "v:false" "v:null" "v:none" "v:count" "v:count1" "v:version"
    "v:val" "v:key" "v:exception" "v:throwpoint" "v:lnum" "v:errmsg"
    "v:shell_error" "v:this_session" "v:char" "v:register" "v:servername")
  "Special VimL `v:' variables with their own face.")

(defconst vimlrs--builtin-funcs
  vimlrs-builtin-function-names
  "VimL builtin function names (from `vimlrs-stdlib').
The ported subset of Vim's funcs.c: len, map, filter, split, substitute,
printf, has, exists, json_encode, matchstr, sort, range, and so on.")

;;; Font-lock.

(defconst vimlrs-font-lock-keywords
  `(;; Statement keywords / control flow.
    (,(regexp-opt vimlrs--statement-keywords 'symbols) . font-lock-keyword-face)
    ;; Common ex commands (also command-like, so the same keyword face).
    (,(regexp-opt vimlrs--ex-commands 'symbols) . font-lock-keyword-face)
    ;; Special `v:' variables (own bold face) — before the generic scope
    ;; rule so `v:true' wins over the catch-all `v:NAME'.
    (,(regexp-opt vimlrs--special-vars 'symbols) . 'vimlrs-special-var-face)
    ;; Scope-namespaced variables: g:foo s:bar b:x w:x t:x l:x a:000 v:x.
    ("\\_<[gsbwtlav]:[A-Za-z_][A-Za-z0-9_]*\\|\\_<a:[0-9]+\\|\\_<a:\\(?:000\\)"
     . 'vimlrs-scope-var-face)
    ;; Built-in functions (font-lock-builtin-face), only when called: name
    ;; immediately followed by `(' so a variable named `count' is not over-lit.
    (,(concat (regexp-opt vimlrs--builtin-funcs 'symbols) "(")
     (1 font-lock-builtin-face))
    ;; User function definitions: `function[!] Name(' — highlight the name,
    ;; including scope/autoload-qualified names (s:Foo, my#auto#load#Func).
    ("\\_<function\\_>!?[ \t]+\\([A-Za-z_][A-Za-z0-9_:#.]*\\)"
     (1 font-lock-function-name-face)))
  "Font-lock keywords for `vimlrs-mode'.
Strings and command-position `\"' comments are handled by the syntax
table and by `vimlrs-syntax-propertize-function'.")

;;; Syntax table.

(defvar vimlrs-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?\" "\"" st)   ; double-quoted string (command-pos -> comment via propertize)
    (modify-syntax-entry ?\' "\"" st)   ; single-quoted (literal) string
    (modify-syntax-entry ?\\ "\\" st)   ; escape (inside double-quoted strings)
    (modify-syntax-entry ?_ "_" st)     ; symbol constituent
    (modify-syntax-entry ?: "_" st)     ; scope prefixes (g: s: v:) read as one symbol
    (modify-syntax-entry ?\n ">" st)    ; comment end (for command-position `"' comments)
    st)
  "Syntax table for `vimlrs-mode'.")

;;; Command-position `"' comments.  A `"' that begins a line (after
;;; optional whitespace) or follows a `|' bar starts a comment to end of
;;; line; a `"' anywhere else is a double-quoted string and is left to the
;;; syntax table.  Per VimL's well-known limitation we only recognize the
;;; command-position form; a trailing `"' after code is treated as a
;;; string, matching how the syntax table classifies it.

(defun vimlrs-syntax-propertize-function (start end)
  "Apply `syntax-table' text properties for command-position comments START..END.
A `\"' at the beginning of a line (after optional whitespace) or
immediately after a `|' bar is marked as comment-start (syntax class
\"<\"); the newline (comment-end \">\" in the syntax table) closes it.  A
`\"' in expression position is left as the string quote set by the syntax
table.  The `syntax-ppss' guard skips any `\"' that is already inside a
string or comment so an in-string bar+quote is not misread."
  (goto-char start)
  (funcall
   (syntax-propertize-rules
    ("\\(?:^[ \t]*\\|[ \t]*|[ \t]*\\)\\(\"\\)"
     (1 (let ((ppss (save-excursion (syntax-ppss (match-beginning 1)))))
          (unless (or (nth 3 ppss) (nth 4 ppss))
            (string-to-syntax "<"))))))
   start end))

;;; Indentation — block-keyword-aware, modeled on `awkrs-indent-line' but
;;; driven by VimL's block-open / block-close keywords rather than braces.

(defconst vimlrs--indent-open-re
  (concat "^[ \t]*\\(?:"
          (regexp-opt '("if" "elseif" "else" "while" "for" "function" "try"
                        "catch" "finally" "augroup"))
          "\\)\\_>")
  "Anchored regexp: a line matching this opens a block for the FOLLOWING line.
Includes the mid-block keywords (else/elseif/catch/finally) because the
lines after them are indented, and `augroup' (its `END' close is handled
separately).")

(defconst vimlrs--indent-close-re
  (concat "^[ \t]*\\(?:"
          (regexp-opt '("endif" "endwhile" "endfor" "endfunction" "endtry"
                        "else" "elseif" "catch" "finally"))
          "\\)\\_>")
  "Anchored regexp: a line matching this dedents relative to its block.
The mid-block keywords (else/elseif/catch/finally) appear here too: the
keyword line itself sits one level out, while its body indents back in.")

(defconst vimlrs--block-end-re
  (regexp-opt '("endif" "endwhile" "endfor" "endfunction" "endtry") 'symbols)
  "Unanchored regexp matching a block-closing keyword anywhere on a line.
Used to detect a one-line block such as `if x | echo 1 | endif' that must
not bump the next line's indentation.")

(defun vimlrs--augroup-end-p ()
  "Return non-nil if the line at point is `augroup END' (closes an augroup)."
  (looking-at-p "^[ \t]*augroup!?[ \t]+\\(?:END\\|end\\)\\_>"))

(defun vimlrs--prev-opens-block-p ()
  "Return non-nil if the line at point opens a block not closed on itself.
A line that both opens and closes its block on one line (e.g.
`if x | echo 1 | endif', or `augroup END') does not deepen the next line."
  (and (looking-at-p vimlrs--indent-open-re)
       (not (vimlrs--augroup-end-p))
       (not (save-excursion
              (re-search-forward vimlrs--block-end-re (line-end-position) t)))))

(defun vimlrs-indent-line ()
  "Indent the current line for `vimlrs-mode'."
  (interactive)
  (let ((indent 0)
        (offset vimlrs-indent-offset))
    (save-excursion
      (beginning-of-line)
      ;; This line dedents if it starts with a block-close / mid-block
      ;; keyword (end*/else/elseif/catch/finally) or is `augroup END'.
      (let ((this-closes (or (looking-at-p vimlrs--indent-close-re)
                             (vimlrs--augroup-end-p))))
        (when (zerop (forward-line -1))
          (while (and (looking-at-p "[ \t]*$") (zerop (forward-line -1))))
          (setq indent (current-indentation))
          ;; The previous (non-blank) line opening a block bumps this one
          ;; a level deeper, unless it closed the block on the same line.
          (when (vimlrs--prev-opens-block-p)
            (setq indent (+ indent offset))))
        (when this-closes
          (setq indent (max 0 (- indent offset))))))
    (if (<= (current-column) (current-indentation))
        (indent-line-to indent)
      (save-excursion (indent-line-to indent)))))

;;; Run / compile — run the current buffer's script through vimlrs.

(defun vimlrs-run-buffer ()
  "Run the current buffer's VimL script through `vimlrs' via `compile'.
The buffer must be visiting a file; it is passed positionally — vimlrs
takes the script as a positional argument, not behind a `-f' flag."
  (interactive)
  (unless buffer-file-name
    (user-error "Buffer is not visiting a file; save it first"))
  (when (and (buffer-modified-p) (y-or-n-p "Save buffer before running? "))
    (save-buffer))
  (require 'compile)
  (compile (format "%s %s"
                   (shell-quote-argument vimlrs-executable)
                   (shell-quote-argument buffer-file-name))))

(defvar vimlrs-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-c") #'vimlrs-run-buffer)
    map)
  "Keymap for `vimlrs-mode'.")

;;; eldoc + completion for builtin functions.

(defun vimlrs-eldoc-function (&rest _)
  "Return the eldoc signature for the VimL builtin at point, or nil."
  (let ((sym (thing-at-point 'symbol t)))
    (and sym (vimlrs-stdlib-signature sym))))

(defun vimlrs-completion-at-point ()
  "`completion-at-point-functions' entry: complete VimL builtin function names."
  (let ((bounds (bounds-of-thing-at-point 'symbol)))
    (when bounds
      (list (car bounds) (cdr bounds) vimlrs-builtin-function-names
            :exclusive 'no))))

;;; LSP integration — eglot (built in since Emacs 29) and lsp-mode, both
;;; optional and configured lazily.  vimlrs is launched with ONLY `--lsp'
;;; (an appended `--stdio' is rejected by the binary).

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               `(vimlrs-mode . (,vimlrs-executable "--lsp"))))

(with-eval-after-load 'lsp-mode
  (add-to-list 'lsp-language-id-configuration '(vimlrs-mode . "vim"))
  (when (fboundp 'lsp-register-client)
    (lsp-register-client
     (make-lsp-client
      :new-connection (lsp-stdio-connection
                       (lambda () (list vimlrs-executable "--lsp")))
      :activation-fn (lsp-activate-on "vim")
      :server-id 'vimlrs-lsp))))

;;;###autoload
(define-derived-mode vimlrs-mode prog-mode "Vimlrs"
  "Major mode for editing VimL (Vimscript), targeting the vimlrs interpreter.

\\{vimlrs-mode-map}"
  :syntax-table vimlrs-mode-syntax-table
  (setq-local font-lock-defaults '(vimlrs-font-lock-keywords))
  (setq-local syntax-propertize-function #'vimlrs-syntax-propertize-function)
  (setq-local comment-start "\" ")
  (setq-local comment-start-skip "\"+[ \t]*")
  (setq-local comment-end "")
  (setq-local indent-line-function #'vimlrs-indent-line)
  (setq-local indent-tabs-mode nil)
  (setq-local tab-width vimlrs-indent-offset)
  (add-hook 'completion-at-point-functions #'vimlrs-completion-at-point nil t)
  (if (boundp 'eldoc-documentation-functions)
      (add-hook 'eldoc-documentation-functions #'vimlrs-eldoc-function nil t)
    (setq-local eldoc-documentation-function #'vimlrs-eldoc-function)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.vim\\'" . vimlrs-mode))

;;;###autoload
(progn
  ;; vimrc family: vimrc .vimrc _vimrc gvimrc .gvimrc _gvimrc, plus
  ;; .nvimrc and init.vim (the latter via the `\.vim' rule above).
  (add-to-list 'auto-mode-alist '("\\(?:\\`\\|/\\)_?g?vimrc\\'" . vimlrs-mode))
  (add-to-list 'auto-mode-alist '("\\(?:\\`\\|/\\)\\.g?vimrc\\'" . vimlrs-mode))
  (add-to-list 'auto-mode-alist '("\\(?:\\`\\|/\\)\\.nvimrc\\'" . vimlrs-mode))
  ;; exrc family: .exrc _exrc.
  (add-to-list 'auto-mode-alist '("\\(?:\\`\\|/\\)_?exrc\\'" . vimlrs-mode))
  (add-to-list 'auto-mode-alist '("\\(?:\\`\\|/\\)\\.exrc\\'" . vimlrs-mode)))

;;;###autoload
(progn
  (add-to-list 'interpreter-mode-alist '("vimlrs" . vimlrs-mode))
  (add-to-list 'interpreter-mode-alist '("vim" . vimlrs-mode))
  (add-to-list 'interpreter-mode-alist '("nvim" . vimlrs-mode)))

(provide 'vimlrs-mode)
;;; vimlrs-mode.el ends here

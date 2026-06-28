;;; face-test.el --- Assert vimlrs-mode font-lock faces -*- lexical-binding: t; -*-

;; Loads vimlrs-mode, fontifies a sample, and asserts the face applied at the
;; first occurrence of each probe token. Run:
;;   emacs --batch -L . -l scripts/face-test.el

;;; Code:

(require 'vimlrs-mode)

(defvar vimlrs-face-test--sample
  (concat
   "\" demo script exercising vimlrs-mode font-lock\n"
   "set number\n"
   "let g:plugin_loaded = v:true\n"
   "let s:total = 0\n"
   "\n"
   "function! Summarize(items) abort\n"
   "  let l:names = []\n"
   "  for item in a:items\n"
   "    if has_key(item, 'name')\n"
   "      call add(l:names, toupper(item.name))\n"
   "    else\n"
   "      echo printf('skip %d', v:count)\n"
   "    endif\n"
   "  endfor\n"
   "  return join(l:names, ', ')\n"
   "endfunction\n"
   "\n"
   "augroup vimlrs_demo\n"
   "  autocmd!\n"
   "augroup END\n"))

(defun vimlrs-face-test--face-of (token)
  "Return the face text-property at the start of the first whole-symbol TOKEN.
Case-sensitive and symbol-bounded so e.g. \"if\" does not match \"endif\"."
  (goto-char (point-min))
  (let ((case-fold-search nil))
    (if (re-search-forward (concat "\\_<" (regexp-quote token) "\\_>") nil t)
        (let ((face (get-text-property (match-beginning 0) 'face)))
          (if (listp face) (car face) face))
      'NOT-FOUND)))

(let ((checks
       '(("set"             . font-lock-keyword-face)
         ("let"             . font-lock-keyword-face)
         ("function"        . font-lock-keyword-face)
         ("for"             . font-lock-keyword-face)
         ("if"              . font-lock-keyword-face)
         ("return"          . font-lock-keyword-face)
         ("endfunction"     . font-lock-keyword-face)
         ("echo"            . font-lock-keyword-face)
         ("call"            . font-lock-keyword-face)
         ("augroup"         . font-lock-keyword-face)
         ("autocmd"         . font-lock-keyword-face)
         ("has_key"         . font-lock-builtin-face)
         ("g:plugin_loaded" . vimlrs-scope-var-face)
         ("s:total"         . vimlrs-scope-var-face)
         ("v:true"          . vimlrs-special-var-face)
         ("v:count"         . vimlrs-special-var-face)
         ("Summarize"       . font-lock-function-name-face)))
      (failed 0))
  (with-temp-buffer
    (insert vimlrs-face-test--sample)
    (vimlrs-mode)
    (font-lock-ensure)
    (let ((com-face (vimlrs-face-test--face-of "exercising")))
      (dolist (probe checks)
        (let* ((token (car probe))
               (want (cdr probe))
               (got (vimlrs-face-test--face-of token))
               (ok (eq got want)))
          (unless ok (setq failed (1+ failed)))
          (princ (format "%s  %-16s want=%-26s got=%s\n"
                         (if ok "PASS" "FAIL") token want got))))
      ;; A single-quoted string: probe a character inside 'skip %d'.
      (goto-char (point-min))
      (let ((str-ok nil))
        (when (re-search-forward "'skip" nil t)
          (setq str-ok (eq (let ((f (get-text-property (1+ (match-beginning 0)) 'face)))
                             (if (listp f) (car f) f))
                           'font-lock-string-face)))
        (unless str-ok (setq failed (1+ failed)))
        (princ (format "%s  %-16s want=%-26s\n"
                       (if str-ok "PASS" "FAIL") "<string>" 'font-lock-string-face)))
      ;; A command-position `"' comment: probe a word on the first line.
      (let ((ok (eq com-face 'font-lock-comment-face)))
        (unless ok (setq failed (1+ failed)))
        (princ (format "%s  %-16s want=%-26s got=%s\n"
                       (if ok "PASS" "FAIL") "<comment>" 'font-lock-comment-face com-face)))))
  (princ (if (zerop failed) "\nALL FACE CHECKS PASSED\n" (format "\n%d CHECK(S) FAILED\n" failed)))
  (kill-emacs (if (zerop failed) 0 1)))

;;; face-test.el ends here

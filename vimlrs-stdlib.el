;;; vimlrs-stdlib.el --- VimL builtin function signatures + docs -*- lexical-binding: t; -*-

;; Copyright (c) 2026 MenkeTechnologies

;; Author: MenkeTechnologies
;; URL: https://github.com/MenkeTechnologies/emacs-viml
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: languages, vim

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Builtin-function metadata for `vimlrs-mode'.  Unlike stryke (whose
;; ~10,450-builtin surface is generated from the binary's own reflection
;; tables into `stryke-stdlib.el'), the `vimlrs' interpreter ports only a
;; fixed subset of Vim's `funcs.c' table, so the builtin surface is small,
;; finite, and tracked by hand here rather than generated.  This table
;; powers:
;;
;;   - `eldoc' signatures in the echo area (one-line synopsis)
;;   - `completion-at-point' over builtin function names
;;
;; The function *names* are also font-locked by `vimlrs-mode' via a plain
;; `regexp-opt' (the list is well under Emacs' regexp-size limit, so no
;; hash-table matcher is needed — that machinery only exists in
;; stryke-stdlib.el because 10,450 names overflow the regexp compiler).

;;; Code:

(defconst vimlrs-builtin-functions
  '(;; List / Dict / collection functions
    ("add"        . "add({list}, {item})  — append {item} to {list}; returns {list}")
    ("copy"       . "copy({expr})  — shallow copy of a List/Dict/Blob")
    ("deepcopy"   . "deepcopy({expr}[, {noref}])  — recursive copy of a List/Dict")
    ("count"      . "count({comp}, {expr}[, {ic}[, {start}]])  — count occurrences of {expr}")
    ("empty"      . "empty({expr})  — 1 if {expr} is empty, else 0")
    ("extend"     . "extend({expr1}, {expr2}[, {expr3}])  — append/merge {expr2} into {expr1}")
    ("filter"     . "filter({expr1}, {expr2})  — keep items of {expr1} where {expr2} is true")
    ("flatten"    . "flatten({list}[, {maxdepth}])  — flatten nested {list} in place")
    ("flattennew" . "flattennew({list}[, {maxdepth}])  — flatten a copy of {list}")
    ("get"        . "get({collection}, {idx/key}[, {default}])  — element or {default}")
    ("has_key"    . "has_key({dict}, {key})  — 1 if {dict} has entry {key}")
    ("index"      . "index({list}, {expr}[, {start}[, {ic}]])  — index of {expr} in {list}, else -1")
    ("insert"     . "insert({list}, {item}[, {idx}])  — insert {item} before index {idx}")
    ("items"      . "items({dict})  — List of [key, value] pairs of {dict}")
    ("join"       . "join({list}[, {sep}])  — join {list} items into a String")
    ("keys"       . "keys({dict})  — List of keys of {dict}")
    ("len"        . "len({expr})  — length of String/List/Dict/Blob")
    ("map"        . "map({expr1}, {expr2})  — replace each item of {expr1} with {expr2}")
    ("max"        . "max({expr})  — maximum value of items in List/Dict {expr}")
    ("min"        . "min({expr})  — minimum value of items in List/Dict {expr}")
    ("range"      . "range({expr}[, {max}[, {stride}]])  — List of numbers")
    ("reduce"     . "reduce({object}, {func}[, {initial}])  — left-fold over {object}")
    ("remove"     . "remove({collection}, {idx}[, {end}])  — remove and return element(s)")
    ("repeat"     . "repeat({expr}, {count})  — {expr} repeated {count} times (String/List)")
    ("reverse"    . "reverse({object})  — reverse a List/Blob in place")
    ("sort"       . "sort({list}[, {func}[, {dict}]])  — sort {list} in place")
    ("values"     . "values({dict})  — List of values of {dict}")
    ;; String functions
    ("char2nr"    . "char2nr({string}[, {utf8}])  — code point of first char of {string}")
    ("escape"     . "escape({string}, {chars})  — escape {chars} in {string} with a backslash")
    ("fnameescape". "fnameescape({string})  — escape {string} for use as a file name")
    ("match"      . "match({expr}, {pat}[, {start}[, {count}]])  — byte index of {pat} match, else -1")
    ("matchstr"   . "matchstr({expr}, {pat}[, {start}[, {count}]])  — matched substring of {pat}")
    ("nr2char"    . "nr2char({number}[, {utf8}])  — String for code point {number}")
    ("pathshorten". "pathshorten({path}[, {len}])  — shorten directory names in {path}")
    ("printf"     . "printf({fmt}, {expr1}...)  — format {expr...} per {fmt} and return the String")
    ("shellescape". "shellescape({string}[, {special}])  — escape {string} for the shell")
    ("soundfold"  . "soundfold({word})  — sound-folded form of {word}")
    ("split"      . "split({string}[, {pat}[, {keepempty}]])  — split {string} into a List")
    ("str2float"  . "str2float({string}[, {quoted}])  — Float value of {string}")
    ("str2nr"     . "str2nr({string}[, {base}[, {quoted}]])  — Number value of {string}")
    ("strcharpart". "strcharpart({src}, {start}[, {len}])  — {len}-char substring from char {start}")
    ("strlen"     . "strlen({string})  — byte length of {string}")
    ("strpart"    . "strpart({src}, {start}[, {len}[, {chars}]])  — {len}-byte substring from {start}")
    ("strridx"    . "strridx({haystack}, {needle}[, {start}])  — last byte index of {needle}")
    ("strtrans"   . "strtrans({string})  — {string} with unprintable chars made printable")
    ("submatch"   . "submatch({nr}[, {list}])  — text of sub-match {nr} in a :substitute")
    ("substitute" . "substitute({string}, {pat}, {sub}, {flags})  — replace {pat} with {sub}")
    ("tolower"    . "tolower({string})  — copy of {string} with uppercase letters lowercased")
    ("toupper"    . "toupper({string})  — copy of {string} with lowercase letters uppercased")
    ("trim"       . "trim({text}[, {mask}[, {dir}]])  — trim leading/trailing chars from {text}")
    ;; Arithmetic / math functions
    ("abs"        . "abs({expr})  — absolute value of {expr}")
    ("and"        . "and({expr}, {expr})  — bitwise AND of two Numbers")
    ("ceil"       . "ceil({expr})  — smallest integral Float not below {expr}")
    ("cos"        . "cos({expr})  — cosine of {expr} (radians)")
    ("float2nr"   . "float2nr({expr})  — Float {expr} truncated to a Number")
    ("floor"      . "floor({expr})  — largest integral Float not above {expr}")
    ("fmod"       . "fmod({expr1}, {expr2})  — remainder of {expr1} / {expr2}")
    ("invert"     . "invert({expr})  — bitwise invert (NOT) of Number {expr}")
    ("isinf"      . "isinf({expr})  — 1/-1 if {expr} is +/- infinity, else 0")
    ("isnan"      . "isnan({expr})  — 1 if Float {expr} is NaN, else 0")
    ("or"         . "or({expr}, {expr})  — bitwise OR of two Numbers")
    ("pow"        . "pow({x}, {y})  — {x} raised to the power {y}")
    ("rand"       . "rand([{expr}])  — pseudo-random 32-bit Number")
    ("round"      . "round({expr})  — {expr} rounded to the nearest integral Float")
    ("sin"        . "sin({expr})  — sine of {expr} (radians)")
    ("sqrt"       . "sqrt({expr})  — square root of {expr}")
    ("srand"      . "srand([{expr}])  — seed for rand(); returns the seed List")
    ("xor"        . "xor({expr}, {expr})  — bitwise XOR of two Numbers")
    ;; Type / conversion functions
    ("eval"       . "eval({string})  — evaluate {string} and return the resulting value")
    ("json_decode". "json_decode({string})  — decode JSON {string} to a Vim value")
    ("json_encode". "json_encode({expr})  — encode Vim value {expr} as a JSON String")
    ("string"     . "string({expr})  — String representation of {expr}")
    ("type"       . "type({expr})  — Number describing the type of {expr}")
    ("blob2list"  . "blob2list({blob})  — List of byte values of {blob}")
    ("list2blob"  . "list2blob({list})  — Blob from a List of byte values")
    ;; Environment / system / introspection functions
    ("argc"       . "argc([{winid}])  — number of files in the argument list")
    ("call"       . "call({func}, {arglist}[, {dict}])  — call {func} with args from {arglist}")
    ("execute"    . "execute({command}[, {silent}])  — run Ex {command}(s) and return the output")
    ("exists"     . "exists({expr})  — 1 if variable/function/option {expr} exists")
    ("function"   . "function({name}[, {arglist}][, {dict}])  — Funcref for {name}")
    ("getenv"     . "getenv({name})  — value of environment variable {name}, or v:null")
    ("getpid"     . "getpid()  — process ID of the interpreter")
    ("has"        . "has({feature}[, {check}])  — 1 if {feature} is supported")
    ("input"      . "input({prompt}[, {text}[, {completion}]])  — read a line from input")
    ("line"       . "line({expr}[, {winid}])  — line number for position {expr}")
    ("localtime"  . "localtime()  — current time as seconds since 1970")
    ("setenv"     . "setenv({name}, {val})  — set environment variable {name} to {val}")
    ("sha256"     . "sha256({string})  — SHA-256 checksum of {string} as a hex String")
    ("strftime"   . "strftime({format}[, {time}])  — format {time} per strftime {format}")
    ("strptime"   . "strptime({format}, {timestring})  — parse {timestring} per {format}")
    ;; Time / profiling functions
    ("reltime"    . "reltime([{start}[, {end}]])  — relative time value")
    ("reltimefloat" . "reltimefloat({time})  — Float seconds from a reltime() value")
    ("reltimestr" . "reltimestr({time})  — String form of a reltime() value")
    ;; Funcref / list-producing helpers
    ("append"     . "append({lnum}, {text})  — append {text} below line {lnum}"))
  "Alist of VimL builtin function name -> one-line signature/synopsis.
Authored from the subset of Vim's `funcs.c' table that the `vimlrs'
interpreter ports; not generated (the surface is small and fixed, unlike
stryke).")

(defconst vimlrs-builtin-function-names
  (mapcar #'car vimlrs-builtin-functions)
  "List of VimL builtin function names (keys of `vimlrs-builtin-functions').")

(defun vimlrs-stdlib-signature (name)
  "Return the one-line signature string for builtin function NAME, or nil."
  (cdr (assoc name vimlrs-builtin-functions)))

(provide 'vimlrs-stdlib)
;;; vimlrs-stdlib.el ends here

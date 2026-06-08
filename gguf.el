;;; gguf.el --- Major mode for viewing GGUF file metadata  -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Your Name

;; Author: Your Name <your-email@example.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "29.1"))
;; Keywords: tools, files
;; URL: https://example.com/gguf

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; A major mode for viewing metadata from GGUF (GPT-Generated Unified
;; Format) model files using the external `ggufmeta' binary.
;;
;; Usage:
;;   M-x gguf-open RET /path/to/model.gguf RET
;;
;; Or simply visit a .gguf file — the mode will automatically activate
;; and display the metadata.
;;
;; The `ggufmeta' binary must be installed separately and available in
;; `exec-path'.  It accepts a single file argument and prints the
;; file's metadata to stdout.

;;; Code:

;;;; Advice on `insert-file-contents' — avoid reading multi-GB GGUF files
;;;; into memory when visiting them.

(defun gguf--on-insert-file-contents (orig-fun filename &optional visit beg end replace)
  "Advice wrapping `insert-file-contents'.

If FILENAME ends in `.gguf', insert a tiny placeholder string
instead of reading the actual (potentially multi-gigabyte) file.
This avoids loading the entire file into memory only to discard
it a moment later when `gguf-mode' replaces the content with
metadata output from the `ggufmeta' binary."
  (if (and (stringp filename)
           (string-suffix-p ".gguf" filename))
      ;; Don't read the file — insert a placeholder.
      (let ((truename (file-truename filename))
            (attrs    (file-attributes filename 'integer)))
        (insert (format ";; %s\n" (file-name-nondirectory filename)))
        (when visit
          (setq buffer-file-name filename)
          (setq buffer-file-truename truename)
          (setq buffer-file-number (nth 7 attrs))
          (set-buffer-modified-p nil)
          (setq buffer-undo-list t))
        (list filename (buffer-size)))
    ;; Not a .gguf file — call the original function normally.
    (apply orig-fun filename visit beg end replace)))

;;;###autoload
(advice-add 'insert-file-contents :around #'gguf--on-insert-file-contents)
;; TODO: revisit this approach — an :around advice on a C primitive is
;; broad.  A more surgical solution like a file-name-handler-alist entry
;; would be preferable, but it requires handling a large set of low-level
;; operations (file-exists-p, file-attributes, expand-file-name, …) with
;; careful recursion inhibition.  The advice is simpler and correct for
;; now.


(defgroup gguf nil
  "Major mode for viewing GGUF file metadata."
  :prefix "gguf-"
  :group 'tools)

(defcustom gguf-ggufmeta-program "ggufmeta"
  "Name or path of the `ggufmeta' executable."
  :type 'string
  :group 'gguf)

(defcustom gguf-auto-update t
  "Non-nil means automatically re-run `ggufmeta' when the file changes.

When `revert-buffer' is called (e.g. via `g'), the metadata will
be refreshed from the `ggufmeta' binary."
  :type 'boolean
  :group 'gguf)

;;; Mode map

(defvar-keymap gguf-mode-map
  :doc "Keymap for `gguf-mode'."
  "g"     #'gguf-refresh
  "q"     #'quit-window
  "n"     #'next-line
  "p"     #'previous-line
  "RET"   #'gguf-show-help)

;;; Help

(defun gguf-show-help ()
  "Display brief help for `gguf-mode'."
  (interactive)
  (describe-function 'gguf-mode))

;;; Core

(defun gguf--run (filename)
  "Run `ggufmeta' on FILENAME and return the output as a string.
Raise an error if the binary is not found or exits non-zero."
  (let ((executable (executable-find gguf-ggufmeta-program)))
    (unless executable
      (error "Cannot find `%s' in `exec-path'.  Please install the ggufmeta binary"
             gguf-ggufmeta-program))
    (with-temp-buffer
      (unless (zerop (call-process executable nil t nil
                                   (expand-file-name filename)))
        (error "`%s' exited with non-zero status" gguf-ggufmeta-program))
      (buffer-string))))

(defun gguf--insert-header (filename)
  "Insert a header with FILENAME and a separator for the metadata display."
  (let ((name (file-name-nondirectory filename))
        (dir  (file-name-directory  filename)))
    (insert (propertize (format "GGUF file: %s\n" name)
                        'face 'bold
                        'help-echo filename))
    (when dir
      (insert (format "Directory: %s\n" (directory-file-name dir))))
    (insert (make-string (window-width) ?─) "\n")))

(defun gguf--insert-output (filename)
  "Insert the `ggufmeta' output for FILENAME into the current buffer.
Lines containing a colon are split using `string-split'; the key
portion is fontified with `font-lock-keyword-face'."
  (let ((raw (gguf--run filename)))
    (dolist (line (split-string raw "\n" t))
      (pcase (string-split line ":" t 2)
        (`(,key ,val)
         (insert (propertize key 'font-lock-face 'font-lock-keyword-face)
                 ":" val "\n"))
        (_
         (insert line "\n"))))))

(defun gguf-refresh ()
  "Re-run `ggufmeta' on the file associated with the current buffer."
  (interactive)
  (unless (buffer-file-name)
    (user-error "Buffer is not visiting a file"))
  (let ((inhibit-read-only t))
    (erase-buffer)
    (gguf--insert-header (buffer-file-name))
    (gguf--insert-output (buffer-file-name))
    (goto-char (point-min))
    (set-buffer-modified-p nil))
  (message "Refreshed metadata from `%s'" gguf-ggufmeta-program))

;;; Mode definition

;;;###autoload
(define-derived-mode gguf-mode special-mode "GGUF"
  "Major mode for viewing metadata of GGUF model files.

This mode runs the external `ggufmeta' binary to display a
human-readable summary of the file's metadata.  The buffer is
read-only; use \\[gguf-refresh] (`g') to re-run the tool.

\\{gguf-mode-map}"
  :group 'gguf
  :after-hook (when (and gguf-auto-update
                         buffer-file-name
                         (string-suffix-p ".gguf" buffer-file-name))
                (gguf-refresh))
  (setq-local buffer-read-only t)
  (setq-local revert-buffer-function
              (lambda (_ignore-auto _noconfirm)
                (gguf-refresh))))

;;;###autoload
(defun gguf-open (filename)
  "Open a GGUF file and display its metadata using `ggufmeta'.
Interactively, prompt for FILENAME."
  (interactive "fGGUF file: ")
  (let ((buf (generate-new-buffer
              (format "*gguf: %s*" (file-name-nondirectory filename)))))
    (with-current-buffer buf
      (gguf-mode)
      (gguf--insert-header filename)
      (gguf--insert-output filename)
      (goto-char (point-min))
      (setq buffer-file-name (expand-file-name filename))
      (setq buffer-file-truename (file-truename filename))
      (setq buffer-read-only t)
      (set-buffer-modified-p nil))
    (pop-to-buffer buf)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.gguf\\'" . gguf-mode))

(provide 'gguf)

;;; gguf.el ends here

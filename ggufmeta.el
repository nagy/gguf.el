;;; ggufmeta.el --- Major mode for viewing GGUF file metadata  -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Your Name

;; Author: Your Name <your-email@example.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "29.1"))
;; Keywords: tools, files
;; URL: https://example.com/ggufmeta

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
;;   M-x ggufmeta-open RET /path/to/model.gguf RET
;;
;; Or simply visit a .gguf file — the mode will automatically activate
;; and display the metadata.
;;
;; The `ggufmeta' binary must be installed separately and available in
;; `exec-path'.  It accepts a single file argument and prints the
;; file's metadata to stdout.

;;; Code:

(defgroup ggufmeta nil
  "Major mode for viewing GGUF file metadata."
  :prefix "ggufmeta-"
  :group 'tools)

(defcustom ggufmeta-program "ggufmeta"
  "Name or path of the `ggufmeta' executable."
  :type 'string
  :group 'ggufmeta)

(defcustom ggufmeta-auto-update t
  "Non-nil means automatically re-run `ggufmeta' when the file changes.

When `revert-buffer' is called (e.g. via `g'), the metadata will
be refreshed from the `ggufmeta' binary."
  :type 'boolean
  :group 'ggufmeta)

;;; Mode map

(defvar-keymap ggufmeta-mode-map
  :doc "Keymap for `ggufmeta-mode'."
  "g"     #'ggufmeta-refresh
  "q"     #'quit-window
  "n"     #'next-line
  "p"     #'previous-line
  "RET"   #'ggufmeta-show-help)

;;; Help

(defun ggufmeta-show-help ()
  "Display brief help for `ggufmeta-mode'."
  (interactive)
  (describe-function 'ggufmeta-mode))

;;; Core

(defun ggufmeta--run (filename)
  "Run `ggufmeta' on FILENAME and return the output as a string.
Raise an error if the binary is not found or exits non-zero."
  (let ((executable (executable-find ggufmeta-program)))
    (unless executable
      (error "Cannot find `%s' in `exec-path'.  Please install the ggufmeta binary"
             ggufmeta-program))
    (with-temp-buffer
      (unless (zerop (call-process executable nil t nil
                                   (expand-file-name filename)))
        (error "`%s' exited with non-zero status" ggufmeta-program))
      (buffer-string))))

(defun ggufmeta--insert-header (filename)
  "Insert a header with FILENAME and a separator for the metadata display."
  (let ((name (file-name-nondirectory filename))
        (dir  (file-name-directory  filename)))
    (insert (propertize (format "GGUF file: %s\n" name)
                        'face 'bold
                        'help-echo filename))
    (when dir
      (insert (format "Directory: %s\n" (directory-file-name dir))))
    (insert (make-string (window-width) ?─) "\n")))

(defun ggufmeta--insert-output (filename)
  "Insert the `ggufmeta' output for FILENAME into the current buffer.
Lines containing a colon are split using `string-split'; the key
portion is fontified with `font-lock-keyword-face'."
  (let ((raw (ggufmeta--run filename)))
    (dolist (line (split-string raw "\n" t))
      (pcase (string-split line ":" t 2)
        (`(,key ,val)
         (insert (propertize key 'font-lock-face 'font-lock-keyword-face)
                 ":" val "\n"))
        (_
         (insert line "\n"))))))

(defun ggufmeta-refresh ()
  "Re-run `ggufmeta' on the file associated with the current buffer."
  (interactive)
  (unless (buffer-file-name)
    (user-error "Buffer is not visiting a file"))
  (let ((inhibit-read-only t))
    (erase-buffer)
    (ggufmeta--insert-header (buffer-file-name))
    (ggufmeta--insert-output (buffer-file-name))
    (goto-char (point-min))
    (set-buffer-modified-p nil))
  (message "Refreshed metadata from `%s'" ggufmeta-program))

;;; Mode definition

;;;###autoload
(define-derived-mode ggufmeta-mode special-mode "GGUF"
  "Major mode for viewing metadata of GGUF model files.

This mode runs the external `ggufmeta' binary to display a
human-readable summary of the file's metadata.  The buffer is
read-only; use \\[ggufmeta-refresh] (`g') to re-run the tool.

\\{ggufmeta-mode-map}"
  :group 'ggufmeta
  :after-hook (when (and ggufmeta-auto-update
                         buffer-file-name
                         (string-suffix-p ".gguf" buffer-file-name))
                (ggufmeta-refresh))
  (setq-local buffer-read-only t)
  (setq-local revert-buffer-function
              (lambda (_ignore-auto _noconfirm)
                (ggufmeta-refresh))))

;;;###autoload
(defun ggufmeta-open (filename)
  "Open a GGUF file and display its metadata using `ggufmeta'.
Interactively, prompt for FILENAME."
  (interactive "fGGUF file: ")
  (let ((buf (generate-new-buffer
              (format "*ggufmeta: %s*" (file-name-nondirectory filename)))))
    (with-current-buffer buf
      (ggufmeta-mode)
      (ggufmeta--insert-header filename)
      (ggufmeta--insert-output filename)
      (goto-char (point-min))
      (setq buffer-file-name (expand-file-name filename))
      (setq buffer-read-only t)
      (set-buffer-modified-p nil))
    (pop-to-buffer buf)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.gguf\\'" . ggufmeta-mode))

(provide 'ggufmeta)

;;; ggufmeta.el ends here

;;; osx-trash.el --- System trash for OS X           -*- lexical-binding: t; -*-

;; Copyright (C) 2014-2016  Sebastian Wiesner <swiesner@lunaryorn.com>

;; Author: Sebastian Wiesner <swiesner@lunaryorn.com>
;; Version: 0.3-cvs
;; URL: https://github.com/lunaryorn/osx-trash.el
;; Keywords: files, convenience, tools, unix
;; Package-Requires: ((emacs "24.1"))

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Add support for system trash on OS X.  In other words, make
;; `delete-by-moving-to-trash' do what you expect it to do.
;;
;; Emacs does not support the system trash of OS X.  This library
;; provides `osx-trash-move-file-to-trash' as an implementation of
;; `system-move-file-to-trash' for OS X.
;;
;; By default an AppleScript helper is used to actually trash the
;; file using the finder, but that is slow, so you might want to
;; customize option `osx-trash-command' to use a faster command.
;;
;; To enable use of the system trash, call `osx-trash-setup' and
;; set `delete-by-moving-to-trash' to a non-nil value.

;;; Code:

(defconst osx-trash-script-file
  (expand-file-name "trashfile.AppleScript"
                    (file-name-directory
                     (or load-file-name (buffer-file-name)))))

(defcustom osx-trash-command nil
  "Command used to move a file to the trash.

For this command to be used you also have to call `osx-trash-setup'
and set `delete-by-moving-to-trash' to a non-nil value.

This has to be a list of strings, beginning with the executable,
followed by its arguments, if any.  The file name is added as the
last argument.  Alternatively this can be nil (the default), in
which case a bundled Applescript is used.

Applescript is slow, so you might want to use a command named
\"trash\".  Several such commands are available, but they are
not compatible.

- The one from https://github.com/ali-rantakari/trash takes an
  optional \"-F\" argument.  Its documentation does not say so,
  but it has been reported that this argument is necessary to
  actually allow the Finder to restore trashed files.

- The one from https://github.com/sindresorhus/macos-trash does
  not take such an argument."
  :group 'auto-save
  :type '(choice (const :tag "use Applescript helper")
                 (repeat :tag "command and arguments" string)))

(defun osx-trash-move-file-to-trash (file-name)
  "Move FILE-NAME to trash.

Option `osx-trash-command' controls what command is used."
  (let ((file-name (expand-file-name file-name)))
    (with-temp-buffer
      (unless (zerop (if osx-trash-command
                         (apply #'call-process
                                (car osx-trash-command) nil t nil
                                (append (cdr osx-trash-command)
                                        (list file-name)))
                        (call-process "osascript" nil t nil
                                      osx-trash-script-file file-name)))
        (error "Failed to trash %S: %S" file-name (buffer-string))))))

;;;###autoload
(defun osx-trash-setup ()
  "Provide trash support for OS X.

Provide `system-move-file-to-trash' as an alias for
`osx-trash-move-file-to-trash'.

Note that you still need to set `delete-by-moving-to-trash' to a
non-nil value to enable trashing for file operations."
  (when (and (eq system-type 'darwin)
             (not (fboundp 'system-move-file-to-trash)))
    (defalias 'system-move-file-to-trash
      'osx-trash-move-file-to-trash)))

(provide 'osx-trash)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; osx-trash.el ends here

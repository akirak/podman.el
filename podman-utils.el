;;; podman-utils.el --- Utilities for podman.el -*- lexical-binding: t -*-

;; Copyright (C) 2021 Akira Komamura

;; Author: Akira Komamura <akira.komamura@gmail.com>
;; Version: 0.1
;; URL: https://github.com/akirak/podman.el

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This library provides utility functions for podman.el that are not
;; actually specific to the package.

;;; Code:

(require 'ts)

(defun podman--format-duration (seconds)
  "Format a duration in SECONDS into human-friendly format."
  (-let* (((&plist :years :days :hours :minutes) (ts-human-duration seconds)))
    ;; This doesn't follow any strict rules
    (cond
     ((> years 0)
      (format "%d years" years))
     ((> days 60)
      (format "%d months" (/ days 30)))
     ((> days 0)
      (format "%d days" days))
     ((> hours 0)
      (format "%d hours" hours))
     ((> minutes 0)
      (format "%d minutes" minutes))
     (t
      "Just now"))))

(provide 'podman-utils)
;;; podman-utils.el ends here

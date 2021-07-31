;;; podman.el --- Interface to podman -*- lexical-binding: t -*-

;; Copyright (C) 2021 Akira Komamura

;; Author: Akira Komamura <akira.komamura@gmail.com>
;; Version: 0.1
;; Package-Requires: ((emacs "27.1") (ts "0.2") (tablist "1.0") (transient "0.3"))
;; Keywords: convenience processes
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

;; podman.el is a wrapper for Podman. Like docker.el, it provides a
;; tablist interface for interacting with podman.

;;; Code:

(require 'podman-pod)

(provide 'podman)
;;; podman.el ends here

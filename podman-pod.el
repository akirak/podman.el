;;; podman-pod.el --- Interface to podman-pod command -*- lexical-binding: t -*-

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

;; This library provides `podman-pod-list', which displays a list of
;; podman pods. You can use it to manage podman pods from inside
;; Emacs.

;;; Code:

(require 'podman-core)
(require 'podman-utils)

(require 'ts)
(require 'tablist)

(defgroup podman-pod nil
  "Manage Podman pods."
  :group 'podman)

(defconst podman-pod-buffer "*Podman Pods*")

;;;; Tablist interface

;;;###autoload
(defun podman-pod-list ()
  "Display a list of podman pods in tablist."
  (interactive)
  (with-current-buffer (get-buffer-create podman-pod-buffer)
    (let ((inhibit-read-only t))
      (erase-buffer))
    (podman-pod-mode)
    (tablist-revert)
    (pop-to-buffer (current-buffer))))

(defvar podman-pod-mode-map
  (let ((m (make-composed-keymap tablist-mode-map)))
    (define-key m "K" #'podman-pod-kill)
    (define-key m "P" #'podman-pod-pause)
    (define-key m "R" #'podman-pod-restart)
    (define-key m "D" #'podman-pod-rm)
    (define-key m "S" #'podman-pod-start)
    (define-key m "O" #'podman-pod-stop)
    (define-key m "U" #'podman-pod-unpause)
    (define-key m "I" #'podman-pod-inspect)
    m))

(define-derived-mode podman-pod-mode tabulated-list-mode "Podman Pods"
  "Major mode for displaying a list of podman pods."
  (setq tabulated-list-format [("ID" 11 t)
                               ("Name" 10 t)
                               ("Status" 8 t)
                               ("Created" 12 t)
                               ("Infra ID" 12 t)
                               ("# of containers" 3 t)])
  (setq tabulated-list-padding 2)
  ;; I am not sure what would be the best here, so I may change this later.
  (setq tabulated-list-sort-key '("Name" . nil))
  (add-hook 'tabulated-list-revert-hook #'podman-pod-refresh nil t)
  (tabulated-list-init-header)
  (tablist-minor-mode))

(defun podman-pod-refresh ()
  "Refresh the entries in `podman-pod-mode'."
  (setq tabulated-list-entries (podman-pod--entries)))

(defun podman-pod--entries ()
  "Return a list of tablist entries for pods."
  (-map (lambda (plist)
          (list (plist-get plist :Id)
                (vector (substring (plist-get plist :Id) 0 11)
                        (plist-get plist :Name)
                        (plist-get plist :Status)
                        (podman--format-duration
                         (- (float-time)
                            (float-time (parse-iso8601-time-string
                                         (plist-get plist :Created)))))
                        (substring (plist-get plist :InfraId) 0 12)
                        (int-to-string (length (plist-get plist :Containers))))))
        (podman-pod--ps)))

(defun podman-pod--ps ()
  "Return a list of pods."
  (with-temp-buffer
    (let ((errfile (make-temp-file "podman-errors")))
      (unless (zerop (call-process podman-executable nil (list t errfile) nil
                                   "pod" "ps" "--format=json"))
        (error "Error from podman pod ps: %s"
               (with-temp-buffer
                 (insert-file-contents errfile)
                 (buffer-string))))
      (goto-char (point-min))
      (json-parse-buffer :object-type 'plist
                         :array-type 'list
                         :null-object nil))))

;;;; Commands available in the tablist interface

(defun podman-pod--change-state (state)
  "Change the state of the pod at point to STATE."
  (let* ((buffer (generate-new-buffer "*podman*"))
         (proc (start-process "podman" buffer podman-executable
                              "pod" state (tabulated-list-get-id))))
    (let ((message-log-max nil))
      (message "Running podman pod %s on the pod..." state))
    (set-process-sentinel proc
                          (lambda (_ event)
                            (pcase event
                              ("finished\n"
                               (message "")
                               (kill-buffer buffer)
                               (with-current-buffer podman-pod-buffer
                                 (tablist-revert)))
                              ((rx bos "exited abnormally")
                               (message "podman failed: %s"
                                        (with-current-buffer buffer
                                          (buffer-string)))
                               (kill-buffer buffer)
                               (with-current-buffer podman-pod-buffer
                                 (tablist-revert))))))))

(defun podman-pod-start ()
  "Start the pod at point."
  (interactive)
  (podman-pod--change-state "start"))

(defun podman-pod-stop ()
  "Stop the pod at point."
  (interactive)
  (podman-pod--change-state "stop"))

(defun podman-pod-restart ()
  "Restart the pod at point."
  (interactive)
  (podman-pod--change-state "restart"))

(defun podman-pod-pause ()
  "Pause the pod at point."
  (interactive)
  (podman-pod--change-state "pause"))

(defun podman-pod-unpause ()
  "Unpause the pod at point."
  (interactive)
  (podman-pod--change-state "unpause"))

(defun podman-pod-kill ()
  "Kill the pod at point."
  (interactive)
  (podman-pod--change-state "kill"))

(defun podman-pod-rm ()
  "Remove the pod at point."
  ;; TODO: Replace this command with a transient interface to support force (-f) option
  (interactive)
  (podman-pod--change-state "rm"))

(defun podman-pod-inspect ()
  "Inspect the pod at point."
  (interactive)
  (let ((pod-id (tabulated-list-get-id))
        (errfile (make-temp-file "podman-pod-inspect")))
    (unwind-protect
        (with-current-buffer (get-buffer-create (format "*Podman Pod %s*" pod-id))
          (let ((inhibit-read-only t))
            (erase-buffer)
            (unless (zerop (call-process podman-executable nil (list t errfile) nil
                                         "inspect" pod-id))
              (error "Non-zero exit from podman pod inspect: %s"
                     (with-temp-buffer
                       (insert-file-contents errfile)
                       (string-trim (buffer-string))))))
          (goto-char (point-min))
          (read-only-mode t)
          (pop-to-buffer (current-buffer)))
      (delete-file errfile))))

(provide 'podman-pod)
;;; podman-pod.el ends here

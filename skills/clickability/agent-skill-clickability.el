;;; agent-skill-clickability.el --- TUI click wiring diagnostics -*- lexical-binding: t -*-

;; Probe and remediate terminal-Emacs clickability: xterm-mouse-mode,
;; tab-line, clipetty, and per-frame tty setup.

(defun agent-skill-clickability--messages-tail (n)
  "Return the last N lines of *Messages*."
  (when-let ((buf (get-buffer "*Messages*")))
    (with-current-buffer buf
      (save-excursion
        (goto-char (point-max))
        (forward-line (- n))
        (buffer-substring-no-properties (point) (point-max))))))

(defun agent-skill-clickability--launched-with-q-p ()
  "Non-nil if *Messages* carries the diagnostic string Emacs emits under -q."
  (when-let ((tail (agent-skill-clickability--messages-tail 500)))
    (and (string-match-p "Setting 'package-selected-packages' temporarily since \"emacs -q\"" tail) t)))

(defun agent-skill-clickability--frame-info (f)
  (list :name (frame-parameter f 'name)
        :tty-type (frame-parameter f 'tty-type)
        :tty (frame-parameter f 'tty)
        :live (frame-live-p f)
        :type (framep-on-display f)))

(defun agent-skill-clickability-probe ()
  "Report the state of every knob that governs TUI clickability."
  (list
   :xterm-mouse-mode           (bound-and-true-p xterm-mouse-mode)
   :xterm-mouse-translate-fn   (fboundp 'xterm-mouse-translate-extended)
   :global-tab-line-mode       (bound-and-true-p global-tab-line-mode)
   :tab-line-mode-any-buffer   (seq-some (lambda (b) (buffer-local-value 'tab-line-format b))
                                         (seq-take (buffer-list) 20))
   :clipetty-feature           (featurep 'clipetty)
   :global-clipetty-mode       (bound-and-true-p global-clipetty-mode)
   :causal-feature             (featurep 'causal)
   :post-command-hook-length   (length post-command-hook)
   :post-command-hook          post-command-hook
   :tty-setup-hook-length      (length tty-setup-hook)
   :frames                     (mapcar #'agent-skill-clickability--frame-info (frame-list))
   :term-env                   (getenv "TERM")
   :launched-with-q            (agent-skill-clickability--launched-with-q-p)
   :messages-tail              (agent-skill-clickability--messages-tail 25)))

(defun agent-skill-clickability-enable ()
  "Narrow remediation: flip on the three minor modes that power TUI clicks.
Does NOT reload init.el. Returns the resulting probe."
  (unless (display-graphic-p) (xterm-mouse-mode 1))
  (condition-case e (require 'clipetty) (error (message "clipetty: %S" e)))
  (when (fboundp 'global-clipetty-mode) (global-clipetty-mode 1))
  (condition-case e (global-tab-line-mode 1) (error (message "tab-line: %S" e)))
  (agent-skill-clickability-probe))

(provide 'agent-skill-clickability)
;;; agent-skill-clickability.el ends here

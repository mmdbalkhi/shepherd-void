;;; 04-gpg-agent.scm --- GnuPG agent (with optional SSH support).

;; GnuPG 2.2+ on Void: gpg-agent without --supervised or --daemon will
;; fail ("no gpg-agent running in this session").  Using --supervised
;; makes gpg-agent run in the foreground under Shepherd supervision.
;; SSH support is toggled via GPG_SSH at Shepherd start time (see
;; 00-utilities.scm).  When enabled, the SSH socket lands at
;; $XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh — a path ssh-add and other
;; SSH tools find automatically via the agent's own socket discovery.

(define gpg-agent
  (service '(gpg-agent)
           #:documentation
           "GnuPG agent.  With GPG_SSH=yes in the environment, also acts
as an SSH agent (SSH_AUTH_SOCK is set automatically by the agent's socket
discovery)."
           #:requirement '(runtime-dirs)
           #:start
           (make-forkexec-constructor
            (append
             (if %ssh-agent-enabled
                 (list (binary "gpg-agent") "--supervised" "--enable-ssh-support")
                 (list (binary "gpg-agent") "--supervised"))
             '("--no-allow-external-cache"))
            #:environment-variables (base-env)
            #:log-file (log-file "gpg-agent"))
           #:stop (make-kill-destructor)
           #:respawn? #t))

(register-services (list gpg-agent))

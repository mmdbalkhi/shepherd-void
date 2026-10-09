;;; 04-gpg-agent.scm --- GnuPG agent (with optional SSH support).

;; gpg-agent runs in the foreground (no --daemon) so Shepherd can supervise
;; it directly.  SSH support is toggled via GPG_SSH at Shepherd start time
;; (see 00-utilities.scm).  When enabled, the SSH socket lands at
;; $XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh. a path ssh-add and other SSH
;; tools find automatically via the agent's own env discovery.

(define gpg-agent
  (service '(gpg-agent)
           #:documentation
           "GnuPG agent.  With GPG_SSH=yes in the environment, also acts
as an SSH agent (SSH_AUTH_SOCK is set automatically by the agent's socket
discovery)."
           #:requirement '(runtime-dirs)
           #:start
           (make-forkexec-constructor
            (if %ssh-agent-enabled
                (list (binary "gpg-agent") "--enable-ssh-support")
                (list (binary "gpg-agent")))
            #:environment-variables (base-env)
            #:log-file (log-file "gpg-agent"))
           #:stop (make-kill-destructor)
           #:respawn? #t))

(register-services (list gpg-agent))

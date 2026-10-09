;;; 16-guix-daemon.scm --- the Guix build daemon.

;; guix-daemon only needs the store mounted (/gnu, in /etc/fstab via
;; file-systems) and the guixbuild users to exist; it does not need the
;; network.  It is therefore part of the boot-critical set even though it is
;; deliberately kept OUT of the ~boot-ready~ login barrier.

(define guix-daemon
  (service '(guix-daemon)
           #:documentation "Guix build daemon."
           #:requirement '(file-systems)
           #:start (make-forkexec-constructor
                    ;; TODO: lispify
                    '("/var/guix/profiles/per-user/root/current-guix/bin/guix-daemon"
                      "--build-users-group=guixbuild"
                      "--enable-substitutes=yes")
                    #:log-file "/var/log/guix-daemon.log")
           #:stop (make-kill-destructor)
           #:respawn? #t))

(register-services (list guix-daemon))

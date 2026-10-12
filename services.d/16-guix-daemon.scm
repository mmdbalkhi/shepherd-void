;;; 16-guix-daemon.scm --- the Guix build daemon.

;; guix-daemon only needs the store mounted (/gnu, in /etc/fstab via
;; file-systems) and the guixbuild users to exist; it does not need the
;; network.  It must NOT be in the boot-critical set: on foreign distros
;; (e.g. Void), the Guix store libraries are in /gnu/store/* and the
;; dynamic loader can resolve them, but a garbage-collected dependency
;; (e.g. libgpg-error) will cause exit 127 which triggers a respawn loop
;; that wastes CPU and clutters the boot log.  Since Shepherd itself is the
;; only Guix component needed at boot, guix-daemon is moved to fully-online
;; and made non-respawning so a failure is logged but does not cascade.

(define guix-daemon
  (service '(guix-daemon)
           #:documentation "Guix build daemon. Not required for Shepherd-only use."
           #:requirement '(file-systems)
           #:start (make-forkexec-constructor
                     '("/var/guix/profiles/per-user/root/current-guix/bin/guix-daemon"
                       "--build-users-group=guixbuild"
                       "--enable-substitutes=yes")
                     #:log-file "/var/log/guix-daemon.log")
           #:stop (make-kill-destructor)
           #:respawn? #f))  ;; Do NOT respawn — a 127 means a missing store dep, not a crash.

(register-services (list guix-daemon))

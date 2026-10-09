;;; 03-runtime.scm --- runtime directory creation (mounts live elsewhere).

;; Mounting and runtime-directory creation are separate responsibilities, so
;; this service only creates the well-known /run and /var/log runtime spots
;; that several daemons depend on.  It performs no mount.

(define runtime-directories
  (service '(runtime-directories)
           #:documentation "Create early runtime directories under /run, /var/log."
           #:requirement '(run root-rw)
           #:start (lambda _
                     (apply system* "mkdir" "-p"
                            '("/run/runit" "/run/udev" "/run/systemd" "/run/user" "/run/lock"
                              "/run/shepherd" "/var/log/shepherd" "/var/log/socklog"))
                     #t)
           #:stop (const #t)
           #:one-shot? #t))

(register-services (list runtime-directories))

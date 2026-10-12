;;; 01-runtime-dirs.scm --- user runtime directory + session env vars.

;; Sets XDG_RUNTIME_DIR (created by PAM/elogind at login, but we ensure it
;; exists as a safeguard) and DBUS_SESSION_BUS_ADDRESS so that dbus-daemon
;; and every dbus-dependent child can find the user session bus at a
;; predictable path.  This is a no-op when XDG_RUNTIME_DIR is already set
;; correctly (idempotent).
(define runtime-dirs
  (service '(runtime-dirs)
           #:documentation
           "Ensure XDG_RUNTIME_DIR exists and set session env vars on the
Shepherd process so all child services inherit them."
           #:requirement '()
           #:start
           (lambda _
             (let ((rt (or (getenv "XDG_RUNTIME_DIR")
                           (string-append "/run/user/"
                                          (number->string (getuid))))))
               (false-if-exception (mkdir-p rt))
               (setenv "XDG_RUNTIME_DIR" rt)
               (setenv "DBUS_SESSION_BUS_ADDRESS"
                       (string-append "unix:path=" rt "/bus"))
               #t))
           #:stop (const #t)
           #:one-shot? #t))

(register-services (list runtime-dirs))

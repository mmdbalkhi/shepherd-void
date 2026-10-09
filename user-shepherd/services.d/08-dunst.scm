;;; 08-dunst.scm --- notification daemon (Wayland).

;; dunst is a lightweight notification daemon.  It needs a Wayland connection
;; (for notification positioning) and dbus (for the org.freedesktop.Notifications
;; interface).  The dbus connection is inherited from the Shepherd env
;; (DBUS_SESSION_BUS_ADDRESS set by runtime-dirs); the Wayland display is
;; passed via #:environment-variables.

(define dunst
  (service '(dunst notifications)
           #:documentation "dunst notification daemon (Wayland)."
           #:requirement '(graphical-session dbus)
           #:start
           (make-forkexec-constructor
            (list (binary "dunst") "-mode wayland")
            #:environment-variables (wayland-env)
            #:directory %home
            #:log-file (log-file "dunst"))
           #:stop (make-kill-destructor)
           #:respawn? #t))

(register-services (list dunst))

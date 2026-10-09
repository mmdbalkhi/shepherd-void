;;; 02-dbus.scm --- D-Bus user session bus.

;; dbus-daemon --session --nofork keeps the bus in the foreground so
;; Shepherd can supervise it (make-kill-destructor on stop).  The socket
;; lands at $XDG_RUNTIME_DIR/bus; a fixed path that runtime-dirs already
;; published as DBUS_SESSION_BUS_ADDRESS, so all dbus-aware children
;; (pipewire, wireplumber, portal helpers, dunst, etc.) connect transparently.

(define dbus
  (service '(dbus session-bus)
           #:documentation "D-Bus user session bus."
           #:requirement '(runtime-dirs)
           #:start
           (make-forkexec-constructor
            (list (binary "dbus-daemon")
                  "--session" "--nofork" "--nopidfile")
            #:environment-variables (base-env)
            #:log-file (log-file "dbus"))
           #:stop (make-kill-destructor)
           #:respawn? #t))

(register-services (list dbus))

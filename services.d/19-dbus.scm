;;; 19-dbus.scm --- system D-Bus message bus.

;; The runtime directory (/run/dbus, owned by the dbus user, uid/gid 22 on
;; Void) is a runtime-directory concern, so it is a separate one-shot service
;; (~dbus-runtime~) that depends on ~runtime-directories~.  The daemon itself
;; is then started from a plain argv list -- no ~/bin/sh -c~ wrapper, and no
;; conditional ~install || install~ chain.

(define dbus-runtime
  (service '(dbus-runtime)
           #:documentation "Create and chown /run/dbus for the D-Bus system bus (dbus:22)."
           #:requirement '(runtime-directories)
           #:start (make-system-constructor "install -d -m755 -g 22 -o 22 /run/dbus")
           #:stop (const #t)
           #:one-shot? #t))

(define dbus
  (service '(dbus)
           #:documentation "D-Bus system message bus."
           #:requirement '(dbus-runtime dev)
           #:start (make-forkexec-constructor
                    '("/usr/sbin/dbus-daemon" "--system" "--nofork" "--nopidfile")
                    #:log-file "/var/log/dbus.log")
           #:stop (make-kill-destructor)
           #:respawn? #t))

(register-services (list dbus-runtime dbus))

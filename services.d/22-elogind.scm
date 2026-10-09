;;; 22-elogind.scm --- systemd-logind replacement for sessions/seats.

;; On Void, elogind is *activated on demand* by the system D-Bus daemon
;; through /usr/share/dbus-1/system-services/org.freedesktop.login1.service
;; (the .service file Exec=es elogind-wrapper).  Launching elogind.wrapper
;; from a Shepherd service would race that activation and make elogind
;; reclaim org.freedesktop.login1 -- i.e. exactly the bug this used to carry.
;;
;; So this is a purely declarative place-holder: it pins elogind behind
;; ~dbus' (so it cannot be ordered before the bus) and exports the ~elogind~
;; / ~logind' symbols other services may depend on.  The actual daemon is
;; bus-activated, lazily, on the first Login1 call (first graphical or
;; console login handled by PAM).

(define elogind
  (service '(elogind logind)
           #:documentation
           "elogind is D-Bus-activated on Void; this service pins ordering and exports the symbol."
           #:requirement '(dbus)
           #:start (const #t)
           #:stop (const #t)
           #:one-shot? #t))

(register-services (list elogind))

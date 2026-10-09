;;; 06-graphical-session.scm --- barrier for the ready graphical session.

;; This is a lightweight stage (barrier) service.  It does no work itself;
;; its only purpose is its #:requirement '(sway).  All GUI-only daemons
;; depend on this barrier, so they start together once Sway has created the
;; Wayland display, but none of them block Sway startup and they all run
;; in parallel.

(define graphical-session
  (service '(graphical-session)
           #:documentation
           "Barrier: the Wayland compositor (sway) is running and the Wayland
display socket exists.  GUI-only daemons depend on this."
           #:requirement '(sway)
           #:start (const #t)
           #:stop  (const #t)
           #:one-shot? #t))

(register-services (list graphical-session))

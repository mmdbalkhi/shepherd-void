;;; 11-wlsunset.scm --- day/night gamma adjustment.

;; wlsunset adjusts the screen color temperature using the
;; wlr-gamma-control-unstable-v1 protocol.  It needs a Wayland connection
;; and the Sway compositor.  Coordinates: lat 38.0792, lon 46.2887
;; (Tabriz, Iran), temperature 6000K (daytime baseline. the daemon handles
;; the day/night ramp; -t 6000 means daytime temperature).

(define wlsunset
  (service '(wlsunset)
           #:documentation "wlsunset: day/night gamma adjustment for Wayland."
           #:requirement '(graphical-session)
           #:start
           (make-forkexec-constructor
            (list (binary "wlsunset")
                  "-l" "38.0792" "-L" "46.2887" "-t" "6000")
            #:environment-variables (wayland-env)
            #:directory %home
            #:log-file (log-file "wlsunset"))
           #:stop (make-kill-destructor)
           #:respawn? #t))

(register-services (list wlsunset))

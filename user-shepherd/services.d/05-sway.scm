;;; 05-sway.scm --- Sway Wayland compositor (user, respawned).

;; Sway is started by the user Shepherd directly (not by an external TTY
;; login script), so `herd restart sway` works.  It requires only:
;;   * seatd socket (system service at /run/seatd/socket)
;;   * XDG_RUNTIME_DIR (from runtime-dirs, for the Wayland socket)
;;
;; Sway does NOT require dbus to run. it uses the Wayland protocol directly
;; for output/input management.  Portal integration (xdg-desktop-portal) is
;; handled separately by services that depend on BOTH graphical-session and
;; dbus.

(define sway-env
  ;; Base env plus the seatd socket address Sway needs to talk to the
  ;; system seat management daemon.
  (append (base-env)
          (list (string-append "SEATD_SOCKET=/run/seatd/socket"))))

(define sway
  (service '(sway wayland)
           #:documentation "sway Wayland compositor (user service)."
           #:requirement '(runtime-dirs dbus)
           #:start
           (make-forkexec-constructor
            (list (binary "sway"))
            #:environment-variables sway-env
            #:directory %home
            #:log-file (log-file "sway"))
           #:stop (make-kill-destructor)
           #:respawn? #t))

(register-services (list sway))

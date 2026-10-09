;;; WIP :: User Shepherd config (copy to ~/.config/shepherd/config.scm).
;;
;; Run as the regular user (komeil) with:
;;
;;   guix package -i shepherd                   # or the Void `shepherd` package
;;   mkdir -p ~/.config/shepherd
;;   cp -r ~/.dotfiles/shepherd/user-shepherd/services.d \
;;         ~/.config/shepherd/services.d
;;   cp ~/.dotfiles/shepherd/user-shepherd/config.scm \
;;         ~/.config/shepherd/config.scm
;;   shepherd -s /run/shepherd/komeil.socket \
;;       -c ~/.config/shepherd/config.scm -I
;;
;; Expects:
;;   * a system seatd socket at /run/seatd/socket (the root `seatd` service
;;     in Stage 3; this user must be in the `_seatd' group:
;;     usermod -aG _seatd komeil);
;;   * sway etc. installed via guix:
;;     guix install sway swayidle swaylock waybar mako grim slurp;
;;   * XDG_RUNTIME_DIR=/run/user/$UID (elogind on the system side creates it
;;     via PAM when you log in on an agetty with elogind running).
;;
;; `start-in-the-background '(desktop)` pulls the graph: sway -> swaylock.

(use-modules (shepherd service)
             ((ice-9 ftw) #:select (scandir)))

(define %services-directory
  (or (getenv "SHEPHERD_USER_SERVICES")
      (string-append (or (getenv "HOME") "/home/komeil")
                     "/.config/shepherd/services.d")))

(for-each
 (lambda (file)
   (load (string-append %services-directory "/" file)))
 (scandir %services-directory
          (lambda (f)
            (and (string-suffix? ".scm" f)
                 (not (string-prefix? "." f))))))

(define %guix-profile
  (or (getenv "GUIX_PROFILE")
      (string-append (or (getenv "HOME") "/home/komeil")
                     "/.guix-profile")))

(define desktop
  (service '(desktop)
           #:documentation "Stage 4: the user's graphical desktop (Wayland/sway)."
           #:requirement '(sway swaylock)
           #:start (const #t)
           #:stop (const #t)
           #:one-shot? #t))

(register-services (list desktop))

;; `(shepherd service)` exports `start-in-the-background`, not a bare `start`.
;; The background start returns immediately, so the user Shepherd socket is
;; served right away (lets you `herd` the desktop manually if needed).
(start-in-the-background '(desktop))

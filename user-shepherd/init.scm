;;; User Shepherd config (copy to ~/.config/shepherd/init.scm).
;;
;; Run as the regular user with:
;;   guix package -i shepherd
;;   mkdir -p ~/.config/shepherd
;;   cp -r ~/.dotfiles/shepherd/user-shepherd/services.d \
;;         ~/.config/shepherd/services.d
;;   cp ~/.dotfiles/shepherd/user-shepherd/init.scm \
;;         ~/.config/shepherd/init.scm
;;   shepherd -s /run/shepherd/$(id -u).socket \
;;       -c ~/.config/shepherd/init.scm -I
;;
;; Expects:
;;   * a system seatd socket at /run/seatd/socket (the root `seatd` service
;;     in Stage 3; this user must be in the `_seatd' group:
;;     usermod -aG _seatd $USER)
;;   * xbps packages installed (see "Required xbps packages" below)
;;   * XDG_RUNTIME_DIR=/run/user/$UID (elogind on the system side creates it
;;     via PAM when you log in on an agetty with elogind running).
;;
;; Session flow:
;;   Shepherd starts -> loads services.d/*.scm
;;     -> runtime-dirs sets up XDG_RUNTIME_DIR + DBUS_SESSION_BUS_ADDRESS
;;     -> dbus, gpg-agent, pipewire start in parallel
;;     -> sway starts
;;       -> graphical-session barrier becomes ready
;;       -> ALL GUI services start in parallel (dunst, swayidle, portals, etc.)
;;     -> sway-session barrier resolves
;;   `herd restart sway` / `herd restart pipewire` / etc. all work.

(use-modules (shepherd service)
             ((ice-9 ftw) #:select (scandir)))

;; Ensure runtime environment is set *before* loading service files, so that
;; base-env() in 00-utilities.scm captures DBUS_SESSION_BUS_ADDRESS.
(let ((rt (or (getenv "XDG_RUNTIME_DIR")
              (string-append "/run/user/" (number->string (getuid))))))
  (unless (getenv "XDG_RUNTIME_DIR")
    (setenv "XDG_RUNTIME_DIR" rt))
  (unless (getenv "DBUS_SESSION_BUS_ADDRESS")
    (setenv "DBUS_SESSION_BUS_ADDRESS"
            (string-append "unix:path=" rt "/bus"))))

(define %services-directory
  (or (getenv "SHEPHERD_USER_SERVICES")
      (string-append (or (getenv "HOME") "/home/komeil")
                     "/.config/shepherd/services.d")))

;; 1. Load every *.scm (alphabetically) from the services directory.
;;    Each file registers its own services; #:requirement may reference a
;;    service defined in an earlier-loaded file (resolved lazily at start
;;    time).  00-utilities.scm sorts first so helpers are available.
(for-each
 (lambda (file)
   (load (string-append %services-directory "/" file)))
 (scandir %services-directory
          (lambda (f)
            (and (string-suffix? ".scm" f)
                 (not (string-prefix? "." f))))))

;; 2. Top-level barrier: the complete user graphical session.
;;    Its #:requirement pulls in every branch of the graph; Shepherd resolves
;;    them in parallel where the DAG allows.
(define sway-session
  (service '(sway-session desktop graphical-session-user)
           #:documentation
           "Barrier: the complete user graphical session (dbus, audio,
gpg-agent, sway, and all GUI daemons)."
           #:requirement '(dbus pipewire gpg-agent sway graphical-session)
           #:start (const #t)
           #:stop (const #t)
           #:one-shot? #t))

(register-services (list sway-session))

;; 3. Kick off the session.
;;    (shepherd service) exports start-in-the-background, not a bare start.
;;    Resolves the graph and starts services concurrently where possible.
(start-in-the-background '(sway-session))

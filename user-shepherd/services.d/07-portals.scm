;;; 07-portals.scm --- Wayland desktop portals.

;; Two pieces:
;; 1. portals-env (one-shot): publishes WAYLAND_DISPLAY and XDG_CURRENT_DESKTOP
;;    to the D-Bus activation environment via dbus-update-activation-environment,
;;    so dbus-activated services (the portals) inherit the Wayland session.
;;    Requires both graphical-session (sway has started) and dbus (the bus
;;    must exist to publish the env).
;; 2. The portals themselves: started explicitly for reliability rather than
;;    relying on dbus activation alone.

(define portals-env
  (service '(portals-env)
           #:documentation
           "Publish WAYLAND_DISPLAY and XDG_CURRENT_DESKTOP to the D-Bus
activation environment so dbus-activated services (portals) inherit them."
           #:requirement '(graphical-session dbus)
           #:start
           (make-system-constructor
            (string-append
             (binary "dbus-update-activation-environment")
             " WAYLAND_DISPLAY=" %wayland-display
             " XDG_CURRENT_DESKTOP=" %xdg-desktop
             " XDG_SESSION_TYPE=wayland"))
           #:stop (const #t)
           #:one-shot? #t))

(define xdg-desktop-portal
  (service '(xdg-desktop-portal)
           #:documentation
           "xdg-desktop-portal: the host D-Bus interface for desktop portal
requests (file pickers, screencasting, etc.)."
           #:requirement '(portals-env)
           #:start
           (make-forkexec-constructor
            (list (binary "xdg-desktop-portal"))
            #:environment-variables (wayland-env)
            #:directory %home
            #:log-file (log-file "xdg-desktop-portal"))
           #:stop (make-kill-destructor)
           #:respawn? #t))

(define xdg-desktop-portal-wlr
  (service '(xdg-desktop-portal-wlr)
           #:documentation
           "xdg-desktop-portal-wlr: Wayland-specific portal backend
(screencasting, screenshot, idle inhibiting for sway)."
           #:requirement '(xdg-desktop-portal)
           #:start
           (make-forkexec-constructor
            (list (binary "xdg-desktop-portal-wlr"))
            #:environment-variables (wayland-env)
            #:directory %home
            #:log-file (log-file "xdg-desktop-portal-wlr"))
           #:stop (make-kill-destructor)
           #:respawn? #t))

(register-services (list portals-env xdg-desktop-portal xdg-desktop-portal-wlr))

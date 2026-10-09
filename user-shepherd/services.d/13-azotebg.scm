;;; 13-azotebg.scm --- wallpaper setter (one-shot).

;; Azotebg is a one-shot: it queries Sway for connected outputs
;; (via swaymsg) and sets a wallpaper for each, then exits.
;; It is a #:one-shot? service that depends on
;; graphical-session (sway must be running for output queries).

(define azotebg
  (service '(azotebg wallpaper)
           #:documentation
           "Set the desktop wallpaper via azotebg (one-shot, runs after sway)."
           #:requirement '(graphical-session)
           #:start
           (make-forkexec-constructor
            (list (binary "azotebg"))
            #:environment-variables (wayland-env)
            #:directory %home
            #:log-file (log-file "azotebg"))
           #:stop (make-kill-destructor)
           #:one-shot? #t))

(register-services (list azotebg))

;;; 12-clipman.scm --- clipboard history daemon (Wayland).

;; Cliphist writer is a self-contained daemon that monitors the Wayland
;; clipboard and stores history in ~/.local/share/cliphist.db.
;; Sway config bindsym stays as a keybinding (not a daemon):
;;   bindsym Mod4+Shift+v exec cliphist list | wofi -d -i | xargs -r cliphist decode | wl-copy

(define clipman
  (service '(clipman clipboard cliphist)
           #:documentation
           "cliphist: Wayland clipboard history daemon (replaces clipman)."
           #:requirement '(graphical-session)
           #:start
           (make-forkexec-constructor
            (list (binary "cliphist") "writer")
            #:environment-variables (wayland-env)
            #:directory %home
            #:log-file (log-file "clipman"))
           #:stop (make-kill-destructor)
           #:respawn? #t))

(register-services (list clipman))

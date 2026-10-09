;;; 09-swayidle.scm --- idle management + swaylock integration.

;; Replaces the existing `swaylock`-named service (which was actually running
;; swayidle).  swayidle monitors Sway output activity and triggers commands
;; on inactivity.  The config mirrors the Sway config's exec line:
;;   timeout 600s -> dpms off
;;   resume       -> dpms on
;;   before-sleep -> swaylock -f -c 000000
;;
;; swaylock (the locker binary) is invoked by swayidle, so it is not a
;; separate service; it is a dependency of the `swaylock` symbol being
;; available in PATH, which it is when the swaylock xbps package is installed.

(define swayidle
  (service '(swayidle)
           #:documentation
           "swayidle: idle management daemon.  Locks with swaylock on
inactivity and before sleep."
           #:requirement '(graphical-session)
           #:start
           (make-forkexec-constructor
            (list (binary "swayidle") "-w"
                  "timeout" "600" "swaymsg" "output *" "dpms" "off"
                  "resume" "swaymsg" "output *" "dpms" "on"
                  "before-sleep" "swaylock" "-f" "-c" "000000")
            #:environment-variables (wayland-env)
            #:directory %home
            #:log-file (log-file "swayidle"))
           #:stop (make-kill-destructor)
           #:respawn? #t))

(register-services (list swayidle))

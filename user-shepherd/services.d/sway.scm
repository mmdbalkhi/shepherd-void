;; Stage 4 (user, fully-online).

;; sway is a long-running compositor managed as a user respawn service.  The
;; system seatd (Stage 3) already exports /run/seatd/socket; this user just
;; points sway at it.  Add this user to the `_seatd' group:
;;   usermod -aG _seatd komeil

(define (guix-profile)
  (or (getenv "GUIX_PROFILE")
      (string-append (or (getenv "HOME") "/home/komeil") "/.guix-profile")))

(define sway
  (service '(sway wayland)
    #:documentation "sway Wayland compositor (user service)."
    #:requirement '()
    #:start
    (make-forkexec-constructor
     (list "/bin/sh" "-c"
           "export GUIX_PROFILE=${GUIX_PROFILE:-$HOME/.guix-profile}
            export PATH=$GUIX_PROFILE/bin:/usr/bin:/bin
            export SEATD_SOCKET=/run/seatd/socket
            exec sway")
     #:directory (or (getenv "HOME") "/home/komeil")
     #:log-file "/home/komeil/.local/share/sway.log")
    #:stop (make-kill-destructor)
    #:respawn? #t))

;; swayidle keeps the screen locked.  Started once sway is up, stopped with it.
(define swaylock
  (service '(swaylock)
    #:documentation "swayidle/swaylock session-lock helper."
    #:requirement '(sway)
    #:start
    (make-forkexec-constructor
     (list (string-append (guix-profile) "/bin/swayidle")
           "Timeout" "300" "swaylock" "Timeout" "600" "swaymsg" "exit"
           "Timeout" "1800" "swaymsg" "exit")
     #:directory (or (getenv "HOME") "/home/komeil")
     #:log-file "/home/komeil/.local/share/swaylock.log")
    #:stop (make-kill-destructor)
    #:respawn? #t))

(register-services (list sway swaylock))

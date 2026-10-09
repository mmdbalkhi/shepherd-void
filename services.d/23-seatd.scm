;;; 23-seatd.scm --- seat management for Wayland (sway).

;; Void's seatd group is ~_seatd~. seatd must start after udev so device
;; nodes exist, and after /run is writable.

(define seatd
  (service '(seatd)
           #:documentation "seatd seat-management daemon (for sway/etc.)"
           #:requirement '(udev udev-settle run runtime-directories)
           #:start (make-forkexec-constructor
                    '("/usr/sbin/seatd" "-g" "_seatd")
                    #:log-file "/var/log/seatd.log")
           #:stop (make-kill-destructor)
           #:respawn? #t))

(register-services (list seatd))

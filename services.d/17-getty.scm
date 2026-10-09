;;; 17-getty.scm --- virtual terminals on tty1..tty6.

;; Agetty is the interactive tier.  Every getty depends on the boot barrier
;; ~boot-ready~ (defined in 28-boot-stages.scm), so a TTY is never offered
;; before the machine is actually ready to log in.

(define (agetty-binary)
  "Resolve the agetty executable (Void ships it under /usr/sbin)."
  (or (and (file-exists? "/usr/sbin/agetty") "/usr/sbin/agetty")
      (and (file-exists? "/sbin/agetty") "/sbin/agetty")
      (and (file-exists? "/usr/bin/agetty") "/usr/bin/agetty")
      "/usr/sbin/agetty"))

(define* (make-agetty tty #:optional (extra-args '()))
  "Return a respawning agetty service for TTY (e.g. \"tty1\").
EXTRA-ARGS is a list of extra agetty arguments."
  (service
   (list (string->symbol (string-append "agetty-" tty)))
   #:documentation (string-append "Getty on " tty)
   #:requirement '(boot-ready)
   #:start (make-forkexec-constructor
            `(,(agetty-binary) "--noclear" ,tty "linux" ,@extra-args)
            #:log-file (string-append "/var/log/agetty-" tty ".log"))
   #:stop (make-kill-destructor)
   #:respawn? #t))

(define agetty-tty1 (make-agetty "tty1" '("--autologin" "komeil")))
(define agetty-tty2 (make-agetty "tty2"))
(define agetty-tty3 (make-agetty "tty3"))
(define agetty-tty4 (make-agetty "tty4"))
(define agetty-tty5 (make-agetty "tty5"))
(define agetty-tty6 (make-agetty "tty6"))

(register-services
 (list agetty-tty1 agetty-tty2 agetty-tty3 agetty-tty4 agetty-tty5 agetty-tty6))

;;; 29-power.scm --- reboot and halt targets for Shepherd.

;; Since s6-linux-init-hpr no longer works (Shepherd replaced it as PID 1),
;; we define native Shepherd targets that sync disks and write to /proc.

(define reboot
  (service '(reboot)
           #:documentation "Reboot the machine."
           #:requirement '(root-rw)
           #:start (lambda _
                     (sync)
                     (system* "umount" "-a" "-r")
                     (let ((fd (open-file "/proc/sysrq-trigger" "w")))
                       (display "b" fd)
                       (close-port fd))
                     #t)
           #:one-shot? #t))

(define halt
  (service '(halt poweroff)
           #:documentation "Power off the machine."
           #:requirement '(root-rw)
           #:start (lambda _
                     (sync)
                     (system* "umount" "-a" "-r")
                     (let ((fd (open-file "/proc/sysrq-trigger" "w")))
                       (display "o" fd)
                       (close-port fd))
                     #t)
           #:one-shot? #t))

(register-services (list reboot halt))

;;; 29-power.scm --- reboot and halt targets for Shepherd.

;; Since s6-linux-init-hpr no longer works (Shepherd replaced it as PID 1),
;; we define native Shepherd targets that drive the Magic SysRq keys directly.
;;
;; IMPORTANT ordering: the old implementation ran `umount -a -r` *before*
;; triggering SysRq.  That unmounted /run, which deleted the shepherd socket
;; ("Socket deleted; stopping") and killed shepherd, and *then* fired the
;; reboot -- so if the SysRq key never took effect the box was left half-dead
;; with no supervisor.  SysRq 'b'/'o' reboot/halt the kernel immediately and
;; skip the unmount, so we trigger it FIRST (after sync+remount-ro via
;; 's'/'u') and let the kernel tear the filesystems down.

(define (sysrq . keys)
  "Write each KEY to /proc/sysrq-trigger, silently ignoring failures (e.g.
when SysRq is disabled or unavailable to this build)."
  (for-each
   (lambda (key)
     (false-if-exception
      (let ((fd (open-file "/proc/sysrq-trigger" "w")))
        (display key fd)
        (close-port fd))))
   keys))

(define reboot
  (service '(reboot)
           #:documentation "Reboot the machine via the Magic SysRq sequence."
           #:requirement '(root-rw)
           #:start (lambda _
                     (sync)
                     (sysrq "s" "u" "b")   ; sync, remount-ro, reboot
                     #t)
           #:one-shot? #t))

(define halt
  (service '(halt poweroff)
           #:documentation "Power off / halt the machine via the Magic SysRq sequence."
           #:requirement '(root-rw)
           #:start (lambda _
                     (sync)
                     (sysrq "s" "u" "o")   ; sync, remount-ro, poweroff
                     #t)
           #:one-shot? #t))

(register-services (list reboot halt))

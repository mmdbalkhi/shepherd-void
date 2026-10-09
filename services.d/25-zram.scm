;;; 25-zram.scm --- compressed swap on a zram block device.

;; Replaces the old inline shell.  The swap activation is a separate one-shot
;; so the boot graph is explicit; zram only needs the kmod (handled by
;; static-device-nodes/kernel-modules) and the block layer.

(define zram
  (service '(zram swap-zram)
           #:documentation "Set up a zram swap device."
           #:requirement '(static-device-nodes)
           #:start (lambda _
                     (system* "modprobe" "zram")
                     (call-with-output-file "/sys/block/zram0/comp_algorithm"
                       (lambda (p) (display "lz4\n" p)))
                     (call-with-output-file "/sys/block/zram0/disksize"
                       (lambda (p)
                         (display (* 8 1024 1024 1024) p)  ;; 8GB -> B
                         (newline p)))
                     (system* "mkswap" "/dev/zram0")
                     (system* "swapon" "/dev/zram0")
                     #t)
           #:stop (lambda _
                    (system* "swapoff" "/dev/zram0")
                    (call-with-output-file "/sys/block/zram0/reset"
                      (lambda (p) (display "1\n" p)))
                    #t)
           #:one-shot? #t))

(register-services (list zram))

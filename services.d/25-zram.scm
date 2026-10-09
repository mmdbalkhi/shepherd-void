;;; 25-zram.scm --- compressed swap on a zram block device.

;; Replaces the old inline shell.  The swap activation is a separate one-shot
;; so the boot graph is explicit; zram only needs the kmod (handled by
;; static-device-nodes/kernel-modules) and the block layer.

(define zram
  (service '(zram swap-zram)
           #:documentation "Set up a zram swap device."
           #:requirement '(static-device-nodes)
           #:start (make-system-constructor
                    ;; TODO: lispify
                    "modprobe zram 2>/dev/null || true
              echo lz4 > /sys/block/zram0/comp_algorithm 2>/dev/null || true
              echo 8G > /sys/block/zram0/disksize 2>/dev/null || true
              mkswap /dev/zram0 2>/dev/null || true
              swapon /dev/zram0 2>/dev/null || true")
           #:stop (make-system-destructor
                   "swapoff /dev/zram0 2>/dev/null || true
             echo 1 > /sys/block/zram0/reset 2>/dev/null || true")
           #:one-shot? #t))

(register-services (list zram))

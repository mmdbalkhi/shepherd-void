;;; 07-udev.scm --- device event daemon + initial enumeration.

;; udevd itself is a long-running daemon managed by Shepherd (respawn).
;; Triggering rules and settling the queue are a separate one-shot, so the
;; boot graph can express "udev is running" vs "udev finished the initial
;; device pass".

(define udev
  (service '(udev)
           #:documentation "udev device event-management daemon (udevd)."
           #:requirement '(root-rw dev cgroup2
                           static-device-nodes kernel-modules runtime-directories)
           #:start (make-forkexec-constructor
                    '("/usr/sbin/udevd" "--debug")
                    #:log-file "/var/log/udevd.log")
           #:stop (make-kill-destructor)
           #:respawn? #t))

(define udev-settle
  (service '(udev-settle)
           #:documentation "Trigger udev rules and wait for the queue to settle."
           #:requirement '(udev)
           #:start (make-system-constructor  ;; TODO: lispify
                    "udevadm trigger --action=add --type=subsystems 2>/dev/null || true
              udevadm trigger --action=add --type=devices 2>/dev/null || true
              udevadm settle 2>/dev/null || true")
           #:stop (const #t)
           #:one-shot? #t))

(register-services (list udev udev-settle))

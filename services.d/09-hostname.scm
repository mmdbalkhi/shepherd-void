;;; 09-hostname.scm --- set the kernel hostname from /etc/hostname.

(define hostname
  (service '(hostname)
           #:documentation "Set the system hostname from /etc/hostname."
           #:requirement '(root-rw)
           #:start (make-system-constructor ;; TODO: lispify
                    "read -r __h < /etc/hostname 2>/dev/null || __h=machine
              printf '%s' \"$__h\" > /proc/sys/kernel/hostname
              hostname \"$__h\"")
           #:stop (const #t)
           #:one-shot? #t))

(register-services (list hostname))

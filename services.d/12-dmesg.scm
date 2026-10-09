;;; 12-dmesg.scm --- snapshot kernel ring buffer into /var/log/dmesg.log.

(define dmesg
  (service '(dmesg)
           #:documentation "Save the kernel ring buffer to /var/log/dmesg.log."
           #:requirement '(root-rw file-systems)
           #:start
           (make-system-constructor ;; TODO: lispify
            "dmesg > /var/log/dmesg.log 2>/dev/null || true
      if [ \"$(sysctl -n kernel.dmesg_restrict 2>/dev/null)\" = \"1\" ]; then
        chmod 0600 /var/log/dmesg.log
      else
        chmod 0644 /var/log/dmesg.log
      fi")
           #:stop (const #t)
           #:one-shot? #t))

(register-services (list dmesg))

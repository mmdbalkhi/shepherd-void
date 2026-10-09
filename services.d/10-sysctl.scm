;;; 10-sysctl.scm --- apply sysctl settings.

;; sysctl is a boot-critical concern (networking knobs, fs limits), but it
;; does not gate login, so it is kept out of the ~boot-ready~ barrier and may
;; run in parallel with the TTYs being brought up.

(define sysctl
  (service '(sysctl)
           #:documentation "Load /etc/sysctl.conf and /etc/sysctl.d/*.conf."
           #:requirement '(root-rw sys file-systems)
           #:start
           (make-system-constructor ;; TODO: lispify
            "for i in /etc/sysctl.d/*.conf /run/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf; do
        [ -e \"$i\" ] && sysctl -p \"$i\" >/dev/null 2>&1 || true
      done
      sysctl -p /etc/sysctl.conf >/dev/null 2>&1 || true")
           #:stop (const #t)
           #:one-shot? #t))

(register-services (list sysctl))

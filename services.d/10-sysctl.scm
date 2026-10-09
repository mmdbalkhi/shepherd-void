;;; 10-sysctl.scm --- apply sysctl settings.
;; sysctl is a boot-critical concern (networking knobs, fs limits), but it
;; does not gate login, so it is kept out of the ~boot-ready~ barrier and may
;; run in parallel with the TTYs being brought up.

(use-modules (ice-9 ftw)     ;; scandir, file-is-directory?
             (srfi srfi-13)  ;; string things
             )


(define sysctl
  (service '(sysctl)
           #:documentation "Load /etc/sysctl.conf and /etc/sysctl.d/*.conf."
           #:requirement '(root-rw sys file-systems)
           #:start (lambda _
                     (for-each (lambda (dir)
                                 (when (file-is-directory? dir)
                                   (for-each (lambda (f)
                                               (system* "sysctl" "-p" (string-append dir "/" f)))
                                             (scandir dir (lambda (f) (string-suffix? ".conf" f))))))
                               '("/etc/sysctl.d" "/run/sysctl.d" "/usr/lib/sysctl.d"))
                     (when (file-exists? "/etc/sysctl.conf")
                       (system* "sysctl" "-p" "/etc/sysctl.conf"))
                     #t)
           #:stop (const #t)
           #:one-shot? #t))

(register-services (list sysctl))

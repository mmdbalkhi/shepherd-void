;;; 10-timezone.scm --- set timezone

(use-modules (ice-9 rdelim) ;; readline
             (srfi srfi-13) ;; string
             )

(define timezone
  (service '(timezone)
           #:documentation "Set system timezone from /etc/rc.conf or /etc/timezone."
           #:requirement '(root-rw)
           #:start (lambda _
                     (let ((tz (or (read-rc-conf-var "TIMEZONE")
                                   (and (file-exists? "/etc/timezone")
                                        (call-with-input-file "/etc/timezone"
                                          (lambda (p) (string-trim-both (read-line p)))))
                                   "UTC")))
                       (let ((target (string-append "/usr/share/zoneinfo/" tz)))
                         (when (file-exists? target)
                           (false-if-exception (delete-file "/etc/localtime"))
                           (symlink target "/etc/localtime"))))
                     #t)
           #:stop (const #t)
           #:one-shot? #t))

(register-services (list timezone))

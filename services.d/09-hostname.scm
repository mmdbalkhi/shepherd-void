;;; 09-hostname.scm --- set the kernel hostname from /etc/hostname.

(use-modules (ice-9 rdelim) ;; read-line
             (srfi srfi-13)  ;; string things
             )

(define hostname
  (service '(hostname)
           #:documentation "Set the system hostname from /etc/hostname."
           #:requirement '(root-rw)
           #:start (lambda _
                     (let ((h (catch 'system-error
                                (lambda ()
                                  (let ((line (call-with-input-file "/etc/hostname" read-line)))
                                    (if (or (eof-object? line) (string-null? (string-trim-both line)))
                                        "machine"
                                        (string-trim-both line))))
                                (lambda args "machine"))))
                       (call-with-output-file "/proc/sys/kernel/hostname"
                         (lambda (port) (display h port)))
                       (system* "hostname" h))
                     #t)
           #:stop (const #t)
           #:one-shot? #t))

(register-services (list hostname))

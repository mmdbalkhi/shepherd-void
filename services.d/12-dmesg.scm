;;; 12-dmesg.scm --- snapshot kernel ring buffer into /var/log/dmesg.log.
(use-modules  (ice-9 popen)  ;; open-pipe* close-pipe
              (ice-9 rdelim) ;; read-line
              (srfi srfi-13) ;; string things
              )

(define dmesg
  (service '(dmesg)
           #:documentation "Save the kernel ring buffer to /var/log/dmesg.log."
           #:requirement '(root-rw file-systems)
           #:start (lambda _
                     (with-output-to-file "/var/log/dmesg.log"
                       (lambda () (system* "dmesg")))
                     (let ((restrict? (catch 'system-error
                                        (lambda ()
                                          (let ((port (open-pipe* OPEN_READ "sysctl" "-n" "kernel.dmesg_restrict")))
                                            (let ((val (read-line port)))
                                              (close-pipe port)
                                              (string=? (string-trim-both val) "1"))))
                                        (lambda args #f))))
                       (apply system* "chmod" (if restrict? '("0600") '("0644")) '("/var/log/dmesg.log")))
                     #t)
           #:stop (const #t)
           #:one-shot? #t))

(register-services (list dmesg))

;;; 06-kernel-modules.scm --- load modules from modules-load.d + /etc/modules.

(use-modules (ice-9 rdelim) ;; read-line
             (srfi srfi-13)  ;; string things
             )

(define (load-modules-from-file file)
  (when (file-exists? file)
    (call-with-input-file file
      (lambda (port)
        (let loop ((line (read-line port)))
          (unless (eof-object? line)
            (let ((trimmed (string-trim-both line)))
              (unless (or (string-null? trimmed)
                          (string-prefix? "#" trimmed))
                (system* "modprobe" trimmed)))
            (loop (read-line port))))))))

(define kernel-modules
  (service '(kernel-modules)
           #:documentation "Load kernel modules listed by modules-load and /etc/modules."
           #:requirement '(proc runtime-directories)
           #:start (lambda _
                     (system* "modules-load")
                     (load-modules-from-file "/etc/modules")
                     #t)
           #:stop (const #t)
           #:one-shot? #t))

(register-services (list kernel-modules))

;;; 05-static-devnodes.scm --- load modules backing static /dev nodes.

(use-modules (ice-9 popen)  ;; open-pipe* close-pipe
             (ice-9 rdelim) ;; read-line
             (srfi srfi-13) ;; string things
             )

(define (load-static-devnodes)
  (let ((port (open-pipe* OPEN_READ "kmod" "static-nodes" "-f" "devname")))
    (catch 'system-error
      (lambda ()
        (let loop ((line (read-line port)))
          (unless (eof-object? line)
            (let ((parts (string-split line #\space)))
              (unless (null? parts)
                (let ((mod (string-trim-both (car parts))))
                  (unless (string-null? mod)
                    (system* "modprobe" "-bq" mod)))))
            (loop (read-line port)))))
      (lambda args #f))
    (close-pipe port)))

(define static-device-nodes
  (service '(static-device-nodes)
           #:documentation "Load device drivers backing the static nodes in devtmpfs."
           #:requirement '(runtime-directories)
           #:start (lambda _ (load-static-devnodes) #t)
           #:stop (const #t)
           #:one-shot? #t))

(register-services (list static-device-nodes))

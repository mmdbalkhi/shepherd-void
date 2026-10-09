;;; 00-utilities.scm --- shared helpers (loaded first; registers nothing).

;; Because `scandir` in config.scm loads every *.scm file, these helpers are
;; available to every service below.  They encode the small, repeated pieces
;; (mount-option formatting, idempotent mountpoint checks) so that individual
;; service files read like declarative data, not shell.

(use-modules (ice-9 ftw)   ; mkdir-p
             (srfi srfi-1) ; filter
             (shepherd service))

(define (opts->string opts)
  "Render `(\"nosuid\" \"nodev\" ...)` as ` -o nosuid,nodev`.
The empty / `(\"defaults\")` list renders as \"\"."
  (if (or (null? opts) (equal? opts '("defaults")))
      ""
      (string-append " -o " (string-join opts ","))))

(define (mountpoint-q? target)
  "Return #t when TARGET is already a mount point."
  (zero? (system (string-append "mountpoint -q " target))))

(define (ensure-dir dir)
  "Create DIR and parents."
  (catch 'system-error
    (lambda () (mkdir-p dir))
    (lambda args (if (and (pair? args)
                          (= EEXIST (system-error-errno args)))
                     #f (apply throw args)))))

(define (run-or-ignored command . args)
  "Run the primitive COMMAND (an absolute path) with ARGS, treating absence or
a non-zero exit as success -- i.e. the Scheme equivalent of the shell idiom
`(command ... 2>/dev/null || true)' used for best-effort one-shots such as
swapon or seedrng.  Returns a truthy value so Shepherd records success."
  (catch 'system-error
    (lambda () (apply system* command args))
    (lambda _ #t)))

;; A one-shot service that mounts a pseudo-file-system if absent.  `type` is
;; the fstype passed to `mount -t`; `source` the kernel source; `target` the
;; mount point; `options` the list passed via `-o`.  Never unmounts at stop
;; time (pseudo-fs are left to the kernel on shutdown, per project rules).
(define* (pseudo-fs-service name
                            #:key
                            source
                            target
                            type
                            (options '())
                            (requirement '()))
  (service
   (list name)
   #:documentation
   (format #f "Mount pseudo-filesystem ~a on ~a~a."
           type target
           (if (null? options) ""
               (string-append " (options: "
                              (string-join options ",")
                              ")")))
   #:requirement requirement
   #:start
   (make-system-constructor
    (string-append "mountpoint -q " target
                   " || mount" (opts->string options)
                   " -t " type " " source " " target " 2>/dev/null || true"))
   #:stop (const #t)
   #:one-shot? #t))

;; A descriptive, non-working target service grouping several requirements.
;; Used purely to give the boot graph readable named layers.
(define* (stage name documentation requirements)
  (service (list name)
           #:documentation documentation
           #:requirement requirements
           #:start (const #t)
           #:stop (const #t)
           #:one-shot? #t))

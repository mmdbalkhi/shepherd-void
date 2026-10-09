;;; 00-utilities.scm --- shared helpers (loaded first; registers nothing).
;; Because ~scandir~ in config.scm loads every *.scm file, these helpers are
;; available to every service below.  They encode the small, repeated pieces
;; (mount-option formatting, idempotent mountpoint checks) so that individual
;; service files read like declarative data, not shell.

(use-modules (ice-9 ftw)   ; mkdir-p
             (srfi srfi-1) ; filter
             (shepherd service))

(define (opts->string opts)
  "Render ~('nosuid', 'nodev', ...)~ as ~-o nosuid,nodev~.
The empty / ~('default')~ list renders as ''."
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
~(command ... 2>/dev/null || true)' used for best-effort one-shots such as
swapon or seedrng.  Returns a truthy value so Shepherd records success."
  (catch 'system-error
    (lambda () (apply system* command args))
    (lambda _ #t)))

(define (mounted? dir)
  (catch 'system-error
    (lambda ()
      (let ((st-dir (stat dir))
            (st-parent (stat (dirname dir))))
        (not (= (stat:dev st-dir) (stat:dev st-parent)))))
    (lambda args
      ;; If the directory doesn't exist yet, it's not mounted.
      #f)))

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
               (format #f " (options: ~{~a~^,~})" options)))
   #:requirement requirement
   #:start
   (lambda _
     ;; Build the mount command arguments purely as a Scheme list.
     (let ((args (append `("-t" ,type)
                         (if (null? options)
                             '()
                             `("-o" ,(string-join options ",")))
                         `(,source ,target))))
       ;; Attempt to mount. If it fails, check if it's already mounted.
       ;; This makes the service perfectly idempotent without shell scripts.
       (or (zero? (apply system* "mount" args))
           (mounted? target))))
   #:stop (const #t)
   #:one-shot? #t))

;; A descriptive, non-working target service grouping several requirements.
;; Used purely to give the boot graph readable named layers.
(define* (stage name documentation requirements)
  ;; If name is already a list, use it; otherwise, wrap the symbol in a list.
  (service (if (list? name) name (list name))
           #:documentation documentation
           #:requirement requirements
           #:start (const #t)
           #:stop (const #t)
           #:one-shot? #t))

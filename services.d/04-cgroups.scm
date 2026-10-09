;;; 04-cgroups.scm --- cgroup hierarchy mounting.

;; The old setup shipped a large shell block switching on CGROUP_MODE in the
;; middle of a ~while read~ loop over /proc/cgroups.  Here the mode decision
;; and the controller enumeration live in Scheme; only each individual ~mount~
;; is a single small shell command guarded by an idempotency check.

(use-modules (ice-9 ftw)     ; mkdir-p
             (srfi srfi-1)   ; filter, filter-map
             (shepherd service))

(define %cgroup-mode
  ;; Mirrors Void's /etc/rc.conf CGROUP_MODE (default: unified; this box).
  (or (getenv "CGROUP_MODE") "unified"))

(define (mountpoint-q? target)
  (zero? (system (string-append "mountpoint -q " target))))

(define (enabled-cgroup-v1-controllers)
  "Return the names of cgroup v1 controllers flagged ~enabled=1~ in
/proc/cgroups.  Returns the empty list when the file is absent."
  (catch 'done
    (lambda ()
      (let ((port (false-if-exception (open-input-file "/proc/cgroups"))))
        (if port
            (let ((lines '()))
              (do ((line (get-line port) (get-line port)))
                  ((eof-object? line) (set! lines (reverse lines)))
                (set! lines (cons line lines)))
              (close-input-port port)
              (filter-map
               (lambda (line)
                 (let ((f (filter (lambda (s) (not (string=? s "")))
                                  (string-split line char-whitespace))))
                   (and (>= (length f) 4)
                        (string=? (cadddr f) "1")
                        (car f))))
               lines))
            (throw 'done '()))))
    (lambda _ '())))

(define (mount-node type source target opts)
  "Mount a cgroup node, idempotently: skip when already a mount point."
  (unless (mountpoint-q? target)
    (mkdir-p target)
    (system (string-append "mount -t " type
                           (if (null? opts) ""
                               (string-append " -o " (string-join opts ",")))
                           " " source " " target))))

(define (cgroup2-boot)
  "Mount the cgroup v2 hierarchy on unified and hybrid modes (no-op legacy)."
  (when (not (string=? %cgroup-mode "legacy"))
    (mount-node "cgroup2" "cgroup2" "/sys/fs/cgroup" '("nsdelegate"))))

(define (cgroup-v1-boot)
  "Mount cgroup v1 tmpfs + per-controller hierarchies (legacy/hybrid only)."
  (when (member %cgroup-mode '("legacy" "hybrid"))
    (unless (mountpoint-q? "/sys/fs/cgroup")
      (mkdir-p "/sys/fs/cgroup")
      (system "mount -t tmpfs cgroup_root /sys/fs/cgroup"))
    (for-each
     (lambda (controller)
       (mount-node "cgroup" controller
                   (string-append "/sys/fs/cgroup/" controller) '()))
     (enabled-cgroup-v1-controllers))
    ;; systemd-tracking cgroup, for nested systemd instances.
    (mount-node "cgroup" "none,name=systemd" "/sys/fs/cgroup/systemd" '())))

(define cgroup2
  (service '(cgroup2 cgroup-hierarchy)
           #:documentation "Mount the cgroup v2 hierarchy at /sys/fs/cgroup."
           #:requirement '(sys runtime-directories)
           #:start (lambda _ (cgroup2-boot) #t)
           #:stop (const #t)
           #:one-shot? #t))

(define cgroup-v1
  (service '(cgroup-v1)
           #:documentation
           "Mount cgroup v1 hierarchies (legacy/hybrid only; no-op on unified)."
           #:requirement '(sys runtime-directories cgroup2)
           #:start (lambda _ (cgroup-v1-boot) #t)
           #:stop (const #t)
           #:one-shot? #t))

;; Descriptive overlay: the single ~cgroups~ name referenced by boot-ready.
(define cgroups
  (stage 'cgroups "cgroup hierarchies are in place." '(cgroup2 cgroup-v1)))

(register-services (list cgroup2 cgroup-v1 cgroups))

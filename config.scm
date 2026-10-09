(use-modules (shepherd service)
             ((ice-9 ftw) #:select (scandir))
             (srfi srfi-1))

;; Where this configuration lives.  Default to the standard location; the
;; s6 ~rc.init~ script points Shepherd here via ~-c /etc/shepherd/config.scm~.
(define %services-dir
  (or (getenv "SHEPHERD_SERVICES_DIR")
      "/etc/shepherd/services.d"))

;; 1. Load every *.scm (alphabetically) from the services directory.
;;    Each file registers its own services; ~#:requirement~ may reference a
;;    service defined in an earlier-loaded file (dependencies are resolved
;;    lazily at start time, so load order only needs shared helpers first --
;;    which is why 00-utilities.scm sorts before everything else).  The stage
;;    targets (boot-ready, interactive, fully-online, ...) live in
;;    ~28-boot-stages.scm~.
(define (load-services dir)
  (for-each
   (lambda (file)
     (load (string-append dir "/" file)))
   (scandir dir
            (lambda (f)
              (and (string-suffix? ".scm" f)
                   (not (string-prefix? "." f)))))))

(load-services %services-dir)

;; 2. Self-check policy.
;;    Shepherd 0.10.x exposes no public "list all services" API from a config
;;    file (the registry is channel-based and private), so a static
;;    "missing-requirements" scan cannot be done here inline.  Instead:
;;      * graph integrity (no cycles, no dangling requirements) is verified by
;;        the off-line validator (~validate-guile.scm~), run by the author;
;;      * at boot, ~start-in-the-background~ resolves the ~fully-online~ graph
;;        and Shepherd throws/logs an ~unresolved requirement' (or
;;        ~Unregistered service') to /var/log/shepherd.log for any symbol that
;;        is required but never provided -- i.e. boot still fails fast and
;;        loud, just one layer inside the daemon.
;;    This keeps config.scm free of version-coupled internal accessors.

;; 3. Kick off boot by resolving the ~fully-online~ target's graph.  Placed at
;;    the end of config.scm on purpose: Shepherd evaluates this file once at
;;    startup (launched from s6 stage 0) and starts the machine.  ~start-in-the
;;    background' returns immediately so the control socket is served right
;;    away; already-running services are left untouched on a later
;;    ~herd load config.scm~.  (shepherd/service) exports start-in-the-background,
;;    NOT a bare ~start'.
(unless (equal? (getenv "SHEPHERD_NO_AUTOBOOT") "1")
  (start-in-the-background '(fully-online)))

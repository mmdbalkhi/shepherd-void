;;; 15-syslog.scm --- system logger via Void ~socklog' listening on /dev/log.

;; Void ships no syslog by default; the ~socklog~ package (from the
;; ~socklog-void~ configuration) provides it.  socklog runs in the foreground
;; by default (it is meant to be supervised), and writes the syslog messages
;; it receives on /dev/log into /var/log/socklog/<facility>/current.  The
;; spool directories and their ~config~ files are created by ~log-files~.

(define syslog
  (service '(syslog socklog)
           #:documentation "socklog system logger listening on /dev/log."
           #:requirement '(log-files runtime-directories)
           #:start (make-forkexec-constructor
                    '("/usr/bin/socklog" "-U" "unix" "/dev/log")
                    #:log-file "/var/log/socklog/socklog.log")
           #:stop (make-kill-destructor)
           #:respawn? #t))

(register-services (list syslog))

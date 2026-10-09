;;; 14-log-files.scm --- utmp/wtmp/btmp/lastlog + socklog spool + dirs.

;; based on runit/core-services/99-cleanup.sh
;; Creates the accounting and log scaffolding.  Per-service logs are written by
;; Shepherd to their own ~#:log-file~ (and Shepherd auto-creates the parent
;; dir on first write), so here we only lay out the system-wide log/utmp
;; files and the socklog spool directories with their syslog ~config~ files.
;;
;; socklog reads its per-facility ~config~ using svlogd directives:
;;   s<size>  rotate at <size> bytes
;;   n<count> keep <count> rotated files
;;   -*       clear the accept list
;;   +pat     accept messages matching pat

(use-modules (srfi srfi-13) ;; string things
             )

(define log-files
  (service '(log-files utmp)
           #:documentation "Create utmp/wtmp/btmp/lastlog and the socklog spool."
           #:requirement '(root-rw file-systems runtime-directories)
           #:start (lambda _
                     ;; 1. Create the utmp/wtmp/btmp/lastlog files
                     (for-each (lambda (args) (apply system* args))
                               '(("install" "-m0664" "-o" "root" "-g" "utmp" "/dev/null" "/run/utmp")
                                 ("install" "-m0664" "-o" "root" "-g" "utmp" "/dev/null" "/var/log/wtmp")
                                 ("install" "-m0600" "-o" "root" "-g" "utmp" "/dev/null" "/var/log/btmp")
                                 ("install" "-m0600" "-o" "root" "-g" "utmp" "/dev/null" "/var/log/lastlog")))

                     ;; 2. Mark the boot in wtmp (we borrow void's 05-misc.sh `halt -B`)
                     (system* "halt" "-B")

                     ;; 3. socklog spool setup
                     (system* "mkdir" "-p" "/var/log/socklog")
                     (system* "chown" "root:socklog" "/var/log/socklog")
                     (system* "chmod" "2750" "/var/log/socklog")
                     (for-each (lambda (facility)
                                 (let ((dir (string-append "/var/log/socklog/" facility)))
                                   (system* "mkdir" "-p" dir)
                                   (call-with-output-file (string-append dir "/config")
                                     (lambda (port)
                                       (display "s1000000\nn10\n" port)))
                                   (system* "chown" "root:socklog" dir)
                                   (system* "chmod" "0750" dir)))
                               '("messages" "daemon" "cron"))
                     #t)
           #:stop (lambda _
                    ;; Shutdown cleanup (replaces Void's 99-cleanup.sh)
                    (for-each (lambda (args)
                                (unless (file-exists? (last args))
                                  (apply system* args)))
                              '(("install" "-m0664" "-o" "root" "-g" "utmp" "/dev/null" "/var/log/wtmp")
                                ("install" "-m0600" "-o" "root" "-g" "utmp" "/dev/null" "/var/log/btmp")
                                ("install" "-m0600" "-o" "root" "-g" "utmp" "/dev/null" "/var/log/lastlog")))
                    (system* "install" "-dm1777" "/tmp/.X11-unix" "/tmp/.ICE-unix")
                    (for-each (lambda (f) (false-if-exception (delete-file f)))
                              '("/etc/nologin" "/forcefsck" "/forcequotacheck" "/fastboot"))
                    #t)
           #:one-shot? #t))

(register-services (list log-files))

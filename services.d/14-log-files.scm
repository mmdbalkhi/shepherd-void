;;; 14-log-files.scm --- utmp/wtmp/btmp/lastlog + socklog spool + dirs.

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

(define log-files
  (service '(log-files utmp)
           #:documentation
           "Create utmp/wtmp/btmp/lastlog and the socklog spool."
           #:requirement '(root-rw file-systems runtime-directories)
           #:start (make-system-constructor  ;; TODO: lispify
                    "set -e
              # utmp family on the persistent filesystem (/var/log is fstab)
              install -m0664 -o root -g utmp /dev/null /run/utmp
              install -m0664 -o root -g utmp /dev/null /var/log/wtmp
              install -m0600 -o root -g utmp /dev/null /var/log/btmp
              install -m0600 -o root -g utmp /dev/null /var/log/lastlog
              # socklog spool: per-facility queue + svlogd config
              mkdir -p /var/log/socklog
              chown root:socklog /var/log/socklog
              chmod 2750 /var/log/socklog
              for s in messages daemon cron; do
                mkdir -p /var/log/socklog/$s
                cat > /var/log/socklog/$s/config <<'EOF'
s1000000
n10
EOF
                chown root:socklog /var/log/socklog/$s
                chmod 0750 /var/log/socklog/$s
              done")
           #:stop (const #t)
           #:one-shot? #t))

(register-services (list log-files))

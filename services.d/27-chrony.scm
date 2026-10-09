;;; 27-chrony.scm --- NTP client.

;; chrony only needs /var/lib for its drift file and the network; it must NOT
;; block getty, so it lives in fully-online only.

(define chrony
  (service '(chrony ntp)
    #:documentation "chrony NTP client/server."
    #:requirement '(network-manager file-systems)
    #:start (make-forkexec-constructor
             '("/usr/sbin/chronyd" "-n" "-f" "/etc/chrony.conf")
             #:log-file "/var/log/chrony.log")
    #:stop (make-kill-destructor)
    #:respawn? #t))

(register-services (list chrony))

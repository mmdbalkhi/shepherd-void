;;; 20-network.scm --- NetworkManager (primary) and dhcpcd (fallback).

;; NetworkManager is the primary network stack (required by fully-online).
;; ~dhcpcd~ is a fallback: it is NOT pulled in by the boot graph, so the two
;; never fight over the same interface.  If NetworkManager is unavailable or
;; you need it to manage only one link, start dhcpcd manually:
;;   herd start dhcpcd

(define network-manager
  (service '(network-manager networking)
           #:documentation "NetworkManager (primary network stack)."
           #:requirement '(dbus udev file-systems loopback)
           #:start (make-forkexec-constructor
                    '("/usr/sbin/NetworkManager" "--no-daemon")
                    #:log-file "/var/log/NetworkManager.log")
           #:stop (make-kill-destructor)
           #:respawn? #t))

(define dhcpcd
  (service '(dhcpcd)
           #:documentation "dhcpcd (fallback; enable manually if NetworkManager is absent)."
           #:requirement '(loopback file-systems)
           #:start (make-forkexec-constructor
                    '("/sbin/dhcpcd" "-B" "-M" "-q")
                    #:log-file "/var/log/dhcpcd.log")
           #:stop (make-kill-destructor)
           #:respawn? #t))

(register-services (list network-manager dhcpcd))

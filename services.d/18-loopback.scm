;;; 18-loopback.scm --- bring up the loopback interface.

;; lo has no real dependencies beyond the ip tool and the dev pseudo-filesystem,
;; so it can come up in parallel with dbus / nm.

(define loopback
  (service '(loopback)
           #:documentation "Bring the loopback interface up."
           #:requirement '(dev file-systems)
           #:start (lambda _ (zero? (system* "ip" "link" "set" "up" "dev" "lo")))
           #:stop (lambda _ (zero? (system* "ip" "link" "set" "down" "dev" "lo")))
           #:one-shot? #t))

(register-services (list loopback))

;;; 21-polkit.scm --- authority manager.

(define polkit
  (service '(polkit)
    #:documentation "polkit authority manager."
    #:requirement '(dbus)
    #:start (make-forkexec-constructor
             '("/usr/lib/polkit-1/polkitd" "--no-debug")
             #:log-file "/var/log/polkit.log")
    #:stop (make-kill-destructor)
    #:respawn? #t))

(register-services (list polkit))

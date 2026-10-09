;;; 24-acpid.scm --- ACPI event daemon.

;; acpid reads events from /proc/acpi/event (needs sysfs + dev).  It blocks
;; nothing critical, so it stays in fully-online, parallel to dbus/NM.

(define acpid
  (service '(acpid)
    #:documentation "ACPI event daemon."
    #:requirement '(sys udev)
    #:start (make-forkexec-constructor
             '("/usr/sbin/acpid" "--foreground")
             #:log-file "/var/log/acpid.log")
    #:stop (make-kill-destructor)
    #:respawn? #t))

(register-services (list acpid))

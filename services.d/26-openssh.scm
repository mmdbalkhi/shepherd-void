;;; 26-openssh.scm --- OpenSSH server + host-key generation.

(define ssh-keys
  (service '(ssh-keys)
           #:documentation "Generate SSH host keys on first boot."
           #:requirement '(loopback file-systems)
           #:start (lambda _
                     (system* "/usr/bin/ssh-keygen" "-A")
                     #t)
           #:stop (const #t)
           #:one-shot? #t))

(define openssh
  (service '(openssh sshd ssh)
           #:documentation "OpenSSH server."
           #:requirement '(ssh-keys loopback file-systems)
           #:start (make-forkexec-constructor
                    '("/usr/sbin/sshd" "-D")
                    #:log-file "/var/log/sshd.log")
           #:stop (make-kill-destructor)
           #:respawn? #t))

(register-services (list ssh-keys openssh))

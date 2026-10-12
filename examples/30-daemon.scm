;; NN-name.scm --- one line.

;; Why it exists: <sentence>.  Why that dependency list: <edges>.
(define name
  (service '(name alias)
    #:documentation "Human sentence."
    #:requirement '(the-services-it-cannot-run-without)
    #:start  (make-forkexec-constructor '("name" "args" …)
                  #:log-file "/var/log/name.log")
    #:stop   (make-kill-destructor)
    #:respawn? #t))            ; one-shot? #t for transient steps

(register-services (list name))

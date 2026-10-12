;;; NN-name.scm --- one-shot setup task.

(define name
  (service '(name)
    #:documentation "Human sentence."
    #:requirement '(the-services-it-cannot-run-without)
    #:start (lambda _
              ;; Pure Guile: no shell scripts, no make-system-constructor
              (zero? (system* "command" "arg1" "arg2")))
    #:stop (const #t)
    #:one-shot? #t))

(register-services (list name))

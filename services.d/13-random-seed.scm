;;; 13-random-seed.scm --- credit the kernel CSPRNG early.

;; Mirrors Void's 05-misc.sh ~seedrng~.  Best-effort: if seedrng is absent or
;; fails, do not block boot.  Run purely in Scheme (no shell): the only logic
;; here is "try the primitive and tolerate failure", which is composition --
;; the binary itself is the primitive.

(define (seedrng-thunk)
  "Credit the kernel CSPRNG.  seedrng exits immediately after seeding."
  (run-or-ignored "/usr/sbin/seedrng"))

(define random-seed
  (service '(random-seed)
           #:documentation "Credit the kernel CSPRNG with seedrng."
           #:requirement '(root-rw file-systems)
           #:start seedrng-thunk
           #:stop (const #t)
           #:one-shot? #t))

(register-services (list random-seed))

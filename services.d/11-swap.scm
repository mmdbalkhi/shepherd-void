;;; 11-swap.scm --- activate swap areas from /etc/fstab.

;; ~swapon~/~swapoff~ are primitive binaries; the only shell-like logic was the
;; ~|| true~ "don't fail boot if there is no swap".  That is composition, so it
;; lives in Scheme via ~run-or-ignored~.  No ~/bin/sh -c~ needed.

(define (swapon-all)
  (run-or-ignored "/usr/sbin/swapon" "-a"))

(define (swapoff-all)
  (run-or-ignored "/usr/sbin/swapoff" "-a"))

(define swap
  (service '(swap)
           #:documentation "Activate swap areas (~swapon -a~)."
           #:requirement '(file-systems)
           #:start swapon-all
           #:stop swapoff-all
           #:one-shot? #t))

(register-services (list swap))

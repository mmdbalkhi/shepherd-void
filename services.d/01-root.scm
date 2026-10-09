;;; 01-root.scm --- root filesystem remount.

;; ~root-rw~ is intentionally the earliest service: it has NO requirements.
;; The previous config made it depend on ~hostname~, but root-rw -> hostname
;; is not semantically justified (the hostname is set from /etc which lives
;; on root, and nothing on root-rw depends on the hostname).  Instead,
;; pseudo-filesystem services depend on ~root-rw~, expressing the real edge.

(define root-rw
  (service '(root-rw root-filesystem)
           #:documentation "Remount the root file system read/write."
           #:requirement '()
           #:start (lambda _
                     (setenv "LIBMOUNT_FORCE_MOUNT2" "always")
                     (or (zero? (system* "mount" "-o" "remount,rw" "/"))
                         #t))
           #:stop (const #t) ;; Let the kernel handle ro remount on poweroff
           #:one-shot? #t))

(register-services (list root-rw))

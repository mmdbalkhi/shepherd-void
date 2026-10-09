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
           #:start (make-system-constructor
                    "LIBMOUNT_FORCE_MOUNT2=always mount -o remount,rw / 2>/dev/null || true")
           #:stop
           ;; We do *not* remount read-only at shutdown: dracut/firmware will reboot
           ;; or power off, and a failed ro remount must never block shutdown.
           (make-system-destructor
            "LIBMOUNT_FORCE_MOUNT2=always mount -o remount,ro / 2>/dev/null || true")
           #:one-shot? #t))

(register-services (list root-rw))

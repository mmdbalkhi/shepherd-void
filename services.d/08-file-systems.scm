;;; 08-file-systems.scm --- mount local filesystems from /etc/fstab.

;; ~mount -a~ is idempotent: already-mounted entries are skipped, so the
;; btrfs subvolumes that s6 stage 0 already mounted (home, /gnu, /var/log...)
;; are left alone.  We never hard-fail boot on a single mount error (matches
;; Void's behavior for optional/media devices).

(define file-systems
  (service '(file-systems)
           #:documentation
           "Mount all non-network filesystems from /etc/fstab (idempotent)."
           #:requirement '(root-rw run dev udev-settle)
           #:start ;; TODO: lispify(calling function for mount)
           (make-system-constructor
            "mount -a -t nosysfs,nonfs,nonfs4,nosmbfs,nocifs 2>/dev/null || true")
           #:stop
           (make-system-destructor
            "umount -a -t nosysfs,nonfs,nonfs4,nosmbfs,nocifs 2>/dev/null || true")
           #:one-shot? #t))

(register-services (list file-systems))

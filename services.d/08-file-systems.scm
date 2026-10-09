;;; 08-file-systems.scm --- mount local filesystems from /etc/fstab.

;; ~mount -a~ is idempotent: already-mounted entries are skipped, so the
;; btrfs subvolumes that s6 stage 0 already mounted (home, /gnu, /var/log...)
;; are left alone.  We never hard-fail boot on a single mount error (matches
;; Void's behavior for optional/media devices).

(define file-systems
  (service '(file-systems)
           #:documentation "Mount all non-network filesystems from /etc/fstab."
           ;; We depend on tmpfs so /tmp is ready before apps try to use it
           #:requirement '(root-rw tmpfs run dev udev-settle)
           #:start (lambda _
                     (zero? (system* "mount" "-a" "-t" "nosysfs,nonfs,nonfs4,nosmbfs,nocifs")))
           #:stop (lambda _
                    (zero? (system* "umount" "-a" "-t" "nosysfs,nonfs,nonfs4,nosmbfs,nocifs")))
           #:one-shot? #t))

(register-services (list file-systems))

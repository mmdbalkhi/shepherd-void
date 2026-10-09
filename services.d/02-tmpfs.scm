;;; 06-tmpfs.scm --- mount /tmp as tmpfs.

(define tmpfs-tmp
  (service '(tmpfs tmp)
           #:documentation "Mount /tmp as a tmpfs filesystem."
           #:requirement '(root-rw)
           #:start (lambda _
                     ;; Ensure the mount point exists
                     (system* "mkdir" "-p" "/tmp")
                     ;; Mount with strict security and 50% RAM limit
                     (and (zero? (system* "mount" "-t" "tmpfs"
                                          "-o" "mode=1777,nosuid,nodev,size=50%"
                                          "tmpfs" "/tmp"))
                          ;; Belt-and-suspenders: enforce permissions
                          (zero? (system* "chmod" "1777" "/tmp"))))
           #:stop (lambda _ (zero? (system* "umount" "/tmp")))
           #:one-shot? #t))

(register-services (list tmpfs-tmp))

;;; 02-pseudo-fs.scm --- independent pseudo-filesystem services.

;; Replaces the old monolithic ~pseudo-filesystems~ service.  Each pseudo
;; filesystem is its own service so they mount in parallel and so a service
;; can depend on exactly the one it needs (e.g. agetty needs dev-pts).
;;
;; Dependency graph (all under root-rw, all parallelizable):
;;   root-rw
;;    ├── proc
;;    ├── sys    └── securityfs
;;    ├── run
;;    └── dev ── dev-pts / dev-shm   (+ mqueue, efivarfs under sys/dev)

(define pseudo-fs-proc
  (pseudo-fs-service 'proc
                     #:source "proc" #:target "/proc" #:type "proc"
                     #:options '("nosuid" "nodev" "noexec")
                     #:requirement '(root-rw)))

(define pseudo-fs-sys
  (pseudo-fs-service 'sys
                     #:source "sysfs" #:target "/sys" #:type "sysfs"
                     #:options '("nosuid" "nodev" "noexec")
                     #:requirement '(root-rw)))

(define pseudo-fs-run
  (pseudo-fs-service 'run
                     #:source "run" #:target "/run" #:type "tmpfs"
                     #:options '("mode=0755" "nosuid" "nodev" "size=32M")
                     #:requirement '(root-rw)))

(define pseudo-fs-dev
  (pseudo-fs-service 'dev
                     #:source "devtmpfs" #:target "/dev" #:type "devtmpfs"
                     #:options '("nosuid" "mode=755")
                     #:requirement '(root-rw)))

(define pseudo-fs-dev-pts
  (pseudo-fs-service 'dev-pts
                     #:source "devpts" #:target "/dev/pts" #:type "devpts"
                     #:options '("mode=0620" "gid=5" "nosuid" "noexec")
                     #:requirement '(dev)))

(define pseudo-fs-dev-shm
  (pseudo-fs-service 'dev-shm
                     #:source "shm" #:target "/dev/shm" #:type "tmpfs"
                     #:options '("mode=1777" "nosuid" "nodev")
                     #:requirement '(dev)))

(define pseudo-fs-securityfs
  (pseudo-fs-service 'securityfs
                     #:source "securityfs" #:target "/sys/kernel/security" #:type "securityfs"
                     #:options '("nosuid" "nodev" "noexec")
                     #:requirement '(sys)))

(define pseudo-fs-mqueue
  (service '(mqueue)
           #:documentation "Mount /dev/mqueue (best effort)."
           #:requirement '(dev)
           #:start (make-system-constructor
                    "mkdir -p /dev/mqueue && \
              mountpoint -q /dev/mqueue || \
              mount -t mqueue none /dev/mqueue 2>/dev/null || true")
           #:stop (const #t)
           #:one-shot? #t))

(define pseudo-fs-efivarfs
  ;; UEFI-only; a safe no-op on BIOS firmware.
  (service '(efivarfs)
           #:documentation "Mount efivarfs (UEFI only)."
           #:requirement '(sys)
           #:start (make-system-constructor
                    "[ -d /sys/firmware/efi/efivars ] || exit 0
              mkdir -p /sys/firmware/efi/efivars
              mountpoint -q /sys/firmware/efi/efivars || \
              mount -t efivarfs efivarfs /sys/firmware/efi/efivars 2>/dev/null || true")
           #:stop (const #t)
           #:one-shot? #t))

;; Descriptive overlay target used by the boot stages.
(define pseudo-filesystems
  (stage 'pseudo-filesystems
         "All early pseudo-filesystems are mounted."
         '(proc sys run dev dev-pts dev-shm securityfs mqueue efivarfs)))

(register-services
 (list pseudo-fs-proc pseudo-fs-sys pseudo-fs-run pseudo-fs-dev
       pseudo-fs-dev-pts pseudo-fs-dev-shm pseudo-fs-securityfs
       pseudo-fs-mqueue pseudo-fs-efivarfs
       pseudo-filesystems))

;;; 28-boot-stages.scm --- boot barriers and stage targets.

;; Three descriptive stage targets, plus the ~boot-ready~ barrier that gates the
;; interactive gettys. These targets perform no work themselves: their only job
;; is to express ordering through ~#:requirement~ so that the graph is obvious
;; from reading this file.
;;
;;   boot-critical : everything needed to run the store / devices.
;;   boot-ready    : the subset of the above that login actually waits on.
;;   interactive   : virtual terminals.
;;   fully-online  : networking + desktop/session daemons.
;;
;; =agetty= depends on =boot-ready= (NOT on a serial list), so unrelated
;; boot-critical services run in parallel and never block each other.

(use-modules (shepherd service))

;; boot-critical: The absolute minimum to get the kernel, storage, and
;; pseudo-filesystems ready.
(define boot-critical
  (stage 'boot-critical "Stage 1: core system initialization."
         '(root-rw pseudo-filesystems runtime-directories
           static-device-nodes kernel-modules cgroups udev udev-settle
           file-systems tmpfs swap sysctl dmesg guix-daemon)))

;; boot-ready: The barrier behind which gettys wait.
;; Includes user-facing setup like console, timezone, and hwclock.
(define boot-ready
  (stage 'boot-ready "Barrier: root, devices, filesystems, hostname, logging,
and console are ready. Gettys may start once this is up."
         '(boot-critical hostname log-files syslog random-seed
           console-setup timezone hwclock)))

;; interactive: Things that require a TTY or user session.
(define interactive
  (stage 'interactive "Stage 2: local TTYs and user login."
         '(boot-ready agetty-tty1 agetty-tty2 agetty-tty3
           agetty-tty4 agetty-tty5 agetty-tty6)))

;; fully-online: Network and background daemons.
(define fully-online
  (stage 'fully-online "Stage 3: networking, D-Bus, seat/session, SSH, and friends.
These deliberately do NOT gate the gettys."
         '(interactive loopback dbus polkit elogind seatd acpid
                       network-manager zram openssh chrony)))

(register-services (list boot-critical boot-ready interactive fully-online))

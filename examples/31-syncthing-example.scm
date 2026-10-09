;;; 31-syncthing-example.scm --- Syncthing daemon.

;; Example service for the "how to add a service" guide in readme.org.
;; It is kept under examples/, NOT services.d/, so it is registered only when
;; you deliberately copy it in:
;;
;;   cp examples/31-syncthing-example.scm /etc/shepherd/services.d/
;;   # then add `syncthing' to the `fully-online' stage in 28-boot-stages.scm
;;   herd load config.scm
;;
;; Syncthing is a good fully-online citizen: network-bound, not login-critical,
;; and restart-on-crash via #:respawn?.  Its systemd unit ties it to
;; `network-online.target` + `local-fs.target`, which here map to
;; `network-manager` + `file-systems`.

(define syncthing
  (service '(syncthing)
    #:documentation "Syncthing file synchronizer (system instance)."
    #:requirement '(network-manager file-systems)
    #:start (make-forkexec-constructor
             '("/usr/bin/syncthing" "-no-browser" "-gui-address=0.0.0.0:8384")
             #:log-file "/var/log/syncthing.log")
    #:stop (make-kill-destructor)
    #:respawn? #t))

(register-services (list syncthing))

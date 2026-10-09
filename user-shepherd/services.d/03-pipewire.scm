;;; 03-pipewire.scm --- PipeWire audio stack.

;; Dependency chain:
;;   pipewire  ->  wireplumber  ->  pipewire-pulse
;;
;; pipewire is the core daemon; wireplumber is the session manager
;; pipewire-pulse provides PulseAudio wire-protocol compatibility
;; for legacy clients.
;;
;; The audio stack does NOT depend on graphical-session. it works headless
;; and can start before Sway.  Each daemon runs in the foreground (--no-daemon
;; / --foreground) so Shepherd can supervise it.

(define pipewire
  (service '(pipewire)
           #:documentation "PipeWire multimedia server (core daemon)."
           #:requirement '(dbus)
           #:start
           (make-forkexec-constructor
            (list (binary "pipewire") "--no-daemon")
            #:environment-variables (base-env)
            #:log-file (log-file "pipewire"))
           #:stop (make-kill-destructor)
           #:respawn? #t))

(define wireplumber
  (service '(wireplumber)
           #:documentation "PipeWire session manager."
           #:requirement '(pipewire)
           #:start
           (make-forkexec-constructor
            (list (binary "wireplumber"))
            #:environment-variables (base-env)
            #:log-file (log-file "wireplumber"))
           #:stop (make-kill-destructor)
           #:respawn? #t))

(define pipewire-pulse
  (service '(pipewire-pulse pulseaudio)
           #:documentation "PipeWire PulseAudio compatibility bridge."
           #:requirement '(wireplumber)
           #:start
           (make-forkexec-constructor
            (list (binary "pipewire-pulse") "--no-daemon")
            #:environment-variables (base-env)
            #:log-file (log-file "pipewire-pulse"))
           #:stop (make-kill-destructor)
           #:respawn? #t))

(register-services (list pipewire wireplumber pipewire-pulse))

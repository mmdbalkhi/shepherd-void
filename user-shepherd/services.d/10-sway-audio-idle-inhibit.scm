;;; 10-sway-audio-idle-inhibit.scm --- keep screen from sleeping during audio.

;; Monitors the PulseAudio server (provided by pipewire-pulse) for active
;; playback and inhibits swayidle's idle timer while audio is playing.
;; Requires both the compositor (via graphical-session) and the audio
;; bridge (pipewire-pulse), without either, the daemon has no purpose.

(define sway-audio-idle-inhibit
  (service '(sway-audio-idle-inhibit)
           #:documentation
           "Prevent idle-sleep while audio is playing (connects to Sway IPC
and PulseAudio server)."
           #:requirement '(graphical-session pipewire-pulse)
           #:start
           (make-forkexec-constructor
            (list (binary "sway-audio-idle-inhibit"))
            #:environment-variables (wayland-env)
            #:directory %home
            #:log-file (log-file "sway-audio-idle-inhibit"))
           #:stop (make-kill-destructor)
           #:respawn? #t))

(register-services (list sway-audio-idle-inhibit))

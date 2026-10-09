;;; 00-utilities.scm --- shared helpers for user Shepherd services.

;; Loaded first (alphabetically); registers no services.
;; Provides binary resolution, env-var construction, and log-file helpers
;; so that individual service files read like declarative data.

(use-modules (srfi srfi-1) ; find, delete-duplicates, remove
             (shepherd service))

;; mkdir-p: create DIR and parents. Defined locally to avoid depending on
;; (ice-9 ftw) availability variations across some Guile builds.
(define* (mkdir-p dir #:optional (mode #o755))
  (let loop ((parts (string-split dir #\/))
             (path ""))
    (if (null? parts)
        #t
        (let* ((next (car parts))
               (full (if (string=? path "") next
                         (string-append path "/" next))))
          (unless (or (string=? next "") (file-exists? full))
            (catch 'system-error
              (lambda () (mkdir full mode))
              (lambda args
                ;; If the error is not EEXIST, re-throw it.
                (unless (= (system-error-errno args) EEXIST)
                  (apply throw args)))))
          (loop (cdr parts) full)))))

(define %home
  (or (getenv "HOME") "/home/komeil"))

(define %xdg-state
  (or (getenv "XDG_STATE_HOME")
      (string-append %home "/.local/state")))

(define %shepherd-dir
  (string-append %xdg-state "/shepherd"))

(define %xdg-runtime
  ;; Inherit from the login session; fall back to the standard per-UID path.
  ;; config.scm sets this via setenv before loading service files.
  (or (getenv "XDG_RUNTIME_DIR")
      (string-append "/run/user/"
                     (number->string (getuid)))))

(define %wayland-display
  ;; Sway's default socket name. If the user has a non-default display,
  ;; set WAYLAND_DISPLAY in the environment before starting the user Shepherd.
  (or (getenv "WAYLAND_DISPLAY") "wayland-0"))

(define %xdg-desktop "sway")

(define %ssh-agent-enabled
  ;; Set GPG_SSH=yes to enable SSH-agent support in gpg-agent.
  (member (getenv "GPG_SSH") '("yes" "1" "true")))

(define %log-dir
  (begin
    (mkdir-p %shepherd-dir)
    %shepherd-dir))

(define (log-file name)
  "Return the log file path for user service NAME."
  (string-append %log-dir "/" name ".log"))

(define* (binary name #:optional (hint ""))
  "Resolve an xbps-installed binary by trying common prefixes.
Returns the first existing path, or NAME if none found (so Shepherd
logs a clear 'No such file or directory' error rather than silently
resolving to PATH)."
  (let ((candidates
         (append
          (if (string=? hint "")
              '()
              (list (string-append hint "/" name)))
          (list (string-append "/usr/bin/" name)
                (string-append "/usr/sbin/" name)
                (string-append "/usr/libexec/" name)
                (string-append "/usr/lib/" name)
                (string-append "/bin/" name)))))
    (or (find file-exists? candidates)
        name)))

(define (base-env)
  "Minimal environment variables every user process needs: HOME, PATH,
XDG_RUNTIME_DIR, and DBUS_SESSION_BUS_ADDRESS, captured from the current
(Shepherd) process. config.scm sets DBUS_SESSION_BUS_ADDRESS via setenv
before loading services, so all children inherit the session bus address."
  (let ((path (or (getenv "PATH") "/usr/local/bin:/usr/bin:/bin"))
        (term (or (getenv "TERM") "xterm-256color"))
        (dbus (getenv "DBUS_SESSION_BUS_ADDRESS"))
        (xdg (getenv "XDG_RUNTIME_DIR")))
    (filter identity
            (list (string-append "HOME=" %home)
                  (string-append "PATH=" path)
                  (and xdg (string-append "XDG_RUNTIME_DIR=" xdg))
                  (string-append "TERM=" term)
                  (and dbus (string-append "DBUS_SESSION_BUS_ADDRESS=" dbus))))))

(define (wayland-env)
  "Environment for GUI services: base env + WAYLAND_DISPLAY + XDG_CURRENT_DESKTOP.
Every Wayland client needs these to connect to the compositor."
  (append (base-env)
          (list (string-append "WAYLAND_DISPLAY=" %wayland-display)
                (string-append "XDG_CURRENT_DESKTOP=" %xdg-desktop)
                (string-append "XDG_SESSION_TYPE=wayland"))))

(define (with-wayland-env proc)
  "Run PROC after setting WAYLAND_DISPLAY and XDG_CURRENT_DESKTOP in the
current process environment (used for one-shots that need the Wayland
display but are started via system* rather than forkexec)."
  (setenv "WAYLAND_DISPLAY" %wayland-display)
  (setenv "XDG_CURRENT_DESKTOP" %xdg-desktop)
  (setenv "XDG_SESSION_TYPE" "wayland")
  (proc))

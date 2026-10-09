;;; 06-kernel-modules.scm --- load modules from modules-load.d + /etc/modules.

(define kernel-modules
  (service '(kernel-modules)
           #:documentation
           "Load kernel modules listed by ~modules-load~ and /etc/modules."
           #:requirement '(proc runtime-directories)
           #:start (make-system-constructor  ;; TODO: lispify
                    "modules-load 2>/dev/null || true
              [ -r /etc/modules ] && while IFS= read -r m; do
                case \"$m\" in ''|'#'*|' '*) ;; esac; modprobe \"$m\" 2>/dev/null
              done < /etc/modules || true")
           #:stop (const #t)
           #:one-shot? #t))

(register-services (list kernel-modules))

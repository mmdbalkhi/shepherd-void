;;; 05-static-devnodes.scm --- load modules backing static /dev nodes.

(define static-device-nodes
  (service '(static-device-nodes)
           #:documentation
           "Load device drivers backing the static nodes in devtmpfs."
           #:requirement '(runtime-directories)
           #:start (make-system-constructor  ;; TODO: lispify
                    "kmod static-nodes -f devname 2>/dev/null \
              | cut -d' ' -f1 \
              | while IFS= read -r m; do [ -n \"$m\" ] && modprobe -bq \"$m\" 2>/dev/null; done \
              || true")
           #:stop (const #t)
           #:one-shot? #t))

(register-services (list static-device-nodes))

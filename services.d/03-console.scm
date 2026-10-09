(define console-setup
  (service '(console-setup)
           #:documentation "Set console font and keyboard map from /etc/rc.conf."
           #:requirement '(dev)
           #:start (lambda _
                     (let ((keymap (read-rc-conf-var "KEYMAP"))
                           (font (read-rc-conf-var "FONT")))
                       (when keymap
                         (system* "loadkeys" "-q" "-u" keymap))
                       (when font
                         (system* "setfont" font)))
                     #t)
           #:stop (const #t)
           #:one-shot? #t))

(register-services (list console-setup))

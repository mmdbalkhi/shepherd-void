;; 10-hwclock.scm --- hwclock set to utc

(define hwclock
  (service '(hwclock)
           #:documentation "Sync hardware clock with system time."
           #:requirement '(root-rw)
           #:start (lambda _
                     ;; Read hardware clock and set system time.
                     ;; Use --utc if your BIOS is set to UTC (recommended),
                     ;; or --localtime if your BIOS is set to local time.
                     (system* "hwclock" "--systz" "--utc")
                     #t)
           #:stop (lambda _
                    ;; Write system time to hardware clock on shutdown.
                    (system* "hwclock" "--systohc" "--utc")
                    #t)
           #:one-shot? #t))

(register-services (list hwclock))

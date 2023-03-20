
(defsystem "adapton"
  :version "0.1.0"
  :description "Language-based semantics for general-purpose incremental computation."
  :author "Jonas Oliveira Rodrigues <jonas.rodrigues@unisoma.com>"
  :license "MIT"
  :depends-on ("atomics"
               "serapeum"
               "trivial-garbage")
  :components ((:module "src"
                :components
                ((:file "micro")
                 (:file "mini"))))
  :description ""
  :in-order-to ((test-op (test-op "adapton/test"))))

(defsystem "adapton/test"
  :description "Test system for adapton"
  :author "Jonas Oliveira Rodrigues <jonas.rodrigues@unisoma.com>"
  :license "MIT"
  :depends-on ("adapton" "fiveam")
  :components ((:module "t"
                :components
                (#+nil(:file "main"))))
  :perform (test-op (o c) (symbol-call :5am :run! :adapton)))


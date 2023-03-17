
(defpackage #:adapton.mini
  (:use #:cl #:adapton.micro #:adapton.utils)
  (:local-nicknames (#:u #:serapeum/bundle))
  (:export))

(in-package #:adapton.mini)

(defparameter *adapting* nil)

(defun force (a)
  (let ((super *adapting*) (*adapting* a))
    (prog1 (compute a)
      (when super (+edge! super a)))))

(defmacro adapt (&body body)
  `(make-athunk (lambda () ,@body)))

#+nil
(u:local
  (defmacro @ (a) `(force ,a))
  (u:def x (cell 8))
  (u:def y (cell 10))
  (u:def a (adapt (- (@ x) (@ y))))
  (format t "(~a - ~a = ~a)~%" (@ x) (@ y) (@ a))
  (set-cell! x 2)
  (format t "(~a - ~a = ~a)~%" (@ x) (@ y) (@ a))
  (set-cell! y 3)
  (format t "(~a - ~a = ~a)~%" (@ x) (@ y) (@ a)))

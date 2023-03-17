
(defpackage #:adapton.micro
  (:use #:cl #:adapton.utils)
  (:local-nicknames (#:u #:serapeum/bundle))
  (:export #:cell
           #:set-cell!
           #:compute
           #:make-athunk
           #:+edge!
           #:-edge!))

(in-package #:adapton.micro)

;; =================================================================================================
;; MicroAdapton
;; =================================================================================================

(u:defunit uncomputed)

(defstruct (adapton
            (:conc-name %)
            (:copier nil)
            (:constructor %make-adapton)
            (:predicate adapton?)
            (:print-object (lambda (a stream)
                             (format stream "#<A ~:[! ~A~;~A~]>"
                                     (%clean? a)
                                     (%result a)))))
  (thunk nil :read-only t)
  (result uncomputed)
  (sub empty-set)
  (super empty-set)
  (clean? nil))

(defun make-athunk (thunk)
  (%make-adapton :thunk thunk))

(defun +edge! (super sub)
  (set-insert sub (%sub super))
  (set-insert super (%super sub)))

(defun -edge! (super sub)
  (set-remove sub (%sub super))
  (set-remove super (%super sub)))

(defun compute (a)
  (cond
    ((%clean? a) (%result a))
    (t
     (dolist (sub (%sub a))
       (-edge! a sub))
     (setf (%clean? a) t)
     (setf (%result a) (funcall (%thunk a)))
     (compute a))))

(defun %dirty! (a)
  (when (%clean? a)
    (setf (%clean? a) nil)
    (dolist (super (%super a))
      (%dirty! super))))

(defun cell (value)
  (let (a)
    (setf a (%make-adapton
             :thunk (lambda () (%result a))
             :result value
             :sub empty-set
             :super empty-set
             :clean? t))))

(defun set-cell! (cell value)
  (setf (%result cell) value)
  (%dirty! cell))

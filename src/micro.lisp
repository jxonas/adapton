
(defpackage #:adapton.micro
  (:use #:cl)
  (:local-nicknames (#:u #:serapeum/bundle))
  (:export #:compute
           #:ref
           #:ref-set!
           #:adapton?
           #:make-athunk
           #:+edge!
           #:-edge!))

(in-package #:adapton.micro)

;; =================================================================================================
;; Sets
;; =================================================================================================

(u:define-constant empty-set '())

(defmacro set-insert (element set)
  `(pushnew ,element ,set :test #'eq))

(defmacro set-remove (element set)
  `(u:removef ,set ,element :test #'eq))

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
                             (format stream "#<~:[! ~A~;~A~]>"
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

(defun ref (value)
  (let (a)
    (setf a (%make-adapton
             :thunk (lambda () (%result a))
             :result value
             :sub empty-set
             :super empty-set
             :clean? t))))

(defun ref-set! (ref value)
  (with-accessors ((result %result)) ref
    (cond
      ((eq result value) (values value nil))
      (t
       (setf result value)
       (%dirty! ref)
       (values value t)))))

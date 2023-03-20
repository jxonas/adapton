
(defpackage #:adapton.mini
  (:use #:cl #:adapton.micro)
  (:local-nicknames (#:u #:serapeum/bundle))
  (:export #:force
           #:adapt
           #:defun/adapt
           #:lambda/adapt
           #:memoize/adapt
           #:avar
           #:avalue
           #:def/avar))

(in-package #:adapton.mini)

(defparameter *adapting* nil)

(defun force (a)
  (let ((super *adapting*) (*adapting* a))
    (prog1 (compute a)
      (when super (+edge! super a)))))

(defmacro adapt (&body body)
  `(make-athunk (lambda () ,@body)))

(defmacro defun/adapt (name lambda-list &body body)
  (u:mvlet*
      ((forms decls doc (u:parse-body body :documentation t))
       (required optional rest keys (u:parse-ordinary-lambda-list lambda-list))
       (argvars `(,@required ,@(mapcar #'car optional) ,@(u:unsplice rest) ,@(mapcan #'car keys))))
    (u:with-gensyms (cache code key entry found?)
      `(let ((,cache (trivial-garbage:make-weak-hash-table
                      :test #'equal
                      :weakness :key
                      :weakness-matters nil)))
         (labels ((,code ,lambda-list
                    ,@(u:unsplice doc)
                    ,@decls
                    (let ((,key ,(if (= 1 (list-length argvars)) (car argvars) `(list ,@argvars))))
                      (multiple-value-bind (,entry ,found?)
                          (gethash ,key ,cache)
                        (force (if ,found? ,entry
                                   (setf (gethash ,key ,cache)
                                         (adapt (block ,name ,@forms)))))))))
           ,@(u:unsplice (when name `(u:defalias ,name #',code)))
           #',code)))))

(defmacro lambda/adapt (lambda-list &body body)
  `(defun/adapt nil ,lambda-list ,@body))

(defun memoize/adapt (fn)
  (lambda/adapt (&rest args)
    (apply fn args)))

(defmacro avar (value)
  `(ref (adapt ,value)))

(defun avalue (var)
  (force (force var)))

(defmacro avalue-set! (var value)
  `(ref-set! ,var (adapt ,value)))

(defsetf avalue avalue-set!)

(defmacro def/avar (name value)
  `(u:def ,name (avar ,value)))

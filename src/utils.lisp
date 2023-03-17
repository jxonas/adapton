
(defpackage #:adapton.utils
  (:use #:cl)
  (:local-nicknames (#:u #:serapeum/bundle))
  (:export

   ;; Sets
   #:empty-set
   #:set-insert
   #:set-remove

    ;; Memoization
   #:defmemo
   #:lambda-memo))

(in-package #:adapton.utils)

;; =================================================================================================
;; Sets
;; =================================================================================================

(u:define-constant empty-set '())

(defmacro set-insert (element set)
  `(pushnew ,element ,set :test #'eq))

(defmacro set-remove (element set)
  `(u:removef ,set ,element :test #'eq))

;; =================================================================================================
;; Memoization
;; =================================================================================================

(defmacro %make-cache (&optional (test #'equal))
  `(trivial-garbage:make-weak-hash-table
    :test ,test
    :weakness :key
    :weakness-matters nil))

(defvar *memo-table* (%make-cache #'eq))

(defun flat-lambda-list (lambda-list)
  (multiple-value-bind (required optional rest keys)
      (u:parse-ordinary-lambda-list lambda-list)
    (append required (mapcar #'car optional) (when rest (list rest)) (mapcan #'car keys))))

(defmacro defmemo (name lambda-list &body body)
  (u:with-gensyms (cache code key entry found?)
    (multiple-value-bind (forms decls doc)
        (u:parse-body body :documentation (and name t))
      `(let ((,cache (%make-cache #'equal)))
         (labels ((,code ,lambda-list
                    ,@(u:unsplice doc)
                    ,@decls
                    (let ((,key (list ,@(flat-lambda-list lambda-list))))
                      (multiple-value-bind (,entry ,found?)
                          (gethash ,key ,cache)
                        (values-list
                         (if ,found? ,entry
                             (setf (gethash ,key ,cache)
                                   (multiple-value-list
                                    (block ,name ,@forms)))))))))
           (prog1 #',code
             (setf (gethash #',code *memo-table*) ,cache)
             ,@(u:unsplice (when name `(u:defalias ,name #',code)))))))))

(defmacro lambda-memo (lambda-list &body body)
  `(defmemo nil ,lambda-list ,@body))

(defun clear-memo (fn)
  (u:when-let ((memo (gethash fn *memo-table*)))
    (prog1 t
      (clrhash memo))))

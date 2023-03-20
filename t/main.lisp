(defpackage #:adapton.tests
  (:use #:cl #:adapton.micro #:adapton.mini #:fiveam)
  (:local-nicknames (#:u #:serapeum/bundle)))

(in-package #:adapton.tests)

(def-suite adapton)
(in-suite adapton)

(defun run-tests ()
  (5am:run! 'adapton))

(test tree-example
  (u:local
    (defun/adapt max-tree (tree)
      (cond
        ((adapton? tree)
         (max-tree (force tree)))
        ((consp tree)
         (max (max-tree (car tree)) (max-tree (cdr tree))))
        (t tree)))

    (defun/adapt max-tree-path (tree)
      (cond
        ((adapton? tree)
         (max-tree-path (force tree)))
        ((consp tree)
         (if (> (max-tree (car tree))
                (max-tree (cdr tree)))
             (cons 'left (max-tree-path (car tree)))
             (cons 'right (max-tree-path (cdr tree)))))
        (t '())))

    (def/avar lucky 7)
    (def/avar t1 (cons 1 2))
    (def/avar t2 (cons 3 4))
    (def/avar tree (cons (avalue t1) (avalue t2)))

    (is (tree-equal (avalue tree) '((1 . 2) 3 . 4)))
    (is (= 4 (max-tree tree)))
    (is (equal '(right right) (max-tree-path tree)))

    (setf (avalue t2) 5)

    (is (tree-equal (avalue tree) '((1 . 2) . 5)))
    (is (= 5 (max-tree tree)))

    (is (equal '(right) (max-tree-path tree)))
    (is (equal '() (max-tree-path (cdr (avalue tree)))))

    (setf (avalue t2) (cons 20 (* 3 (avalue lucky))))

    (is (tree-equal (avalue tree) '((1 . 2) 20 . 21)))
    (is (equal '(right right) (max-tree-path tree)))))


(test spreadsheet-example
  (u:local
    (def/avar n1 1)
    (def/avar n2 2)
    (def/avar n3 3)
    (def/avar p1 (+ (avalue n1) (avalue n2)))
    (def/avar p2 (+ (avalue p1) (avalue n3)))

    (is (= 3 (avalue p1)))
    (is (= 6 (avalue p2)))

    (setf (avalue n1) 5)

    (is (= 7 (avalue p1)))

    (setf (avalue p2) (+ (avalue n3) (avalue p1)))

    (is (= 10 (avalue p2)))

    (setf (avalue p1) 4)
    (is (= 7 (avalue p2)))

    (setf (avalue p1) (+ (avalue n1) (avalue n2)))

    (is (= 10 (avalue p2)))

    (setf (avalue p1) (* (avalue n1) (avalue n2)))

    (is (= 13 (avalue p2)))))

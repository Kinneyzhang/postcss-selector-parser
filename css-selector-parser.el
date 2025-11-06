;;; css-selector-parser.el --- CSS选择器解析器 (Emacs Lisp实现) -*- lexical-binding: t; -*-

;; Copyright (C) 2024

;; Author: Based on postcss-selector-parser
;; Keywords: css, parser, selector
;; Version: 1.0.0

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;;; Commentary:

;; 这是一个CSS选择器解析器的Emacs Lisp实现，基于postcss-selector-parser项目。
;; 它将CSS选择器字符串解析为抽象语法树（AST），支持各种CSS选择器语法。
;;
;; 主要功能：
;; - 词法分析（Tokenization）
;; - 语法分析（Parsing）
;; - AST构建和遍历
;; - 选择器修改和序列化
;;
;; 使用示例：
;;
;;   (css-selector-parse "div.class#id > span:hover")
;;   ;; => AST树结构
;;
;;   (css-selector-walk
;;    (css-selector-parse "div.class")
;;    (lambda (node) (message "Node: %s" (plist-get node :type))))

;;; Code:

(require 'cl-lib)

;;; Token类型定义

(defconst css-token-types
  '((ampersand . 38)          ; &
    (asterisk . 42)           ; *
    (comma . 44)              ; ,
    (colon . 58)              ; :
    (semicolon . 59)          ; ;
    (open-paren . 40)         ; (
    (close-paren . 41)        ; )
    (open-square . 91)        ; [
    (close-square . 93)       ; ]
    (dollar . 36)             ; $
    (tilde . 126)             ; ~
    (caret . 94)              ; ^
    (plus . 43)               ; +
    (equals . 61)             ; =
    (pipe . 124)              ; |
    (greater-than . 62)       ; >
    (space . 32)              ; 空格
    (single-quote . 39)       ; '
    (double-quote . 34)       ; "
    (slash . 47)              ; /
    (bang . 33)               ; !
    (backslash . 92)          ; \
    (cr . 13)                 ; \r
    (feed . 12)               ; \f
    (newline . 10)            ; \n
    (tab . 9)                 ; \t
    ;; 特殊token类型
    (str . -1)                ; 字符串
    (comment . -2)            ; 注释
    (word . -3)               ; 单词
    (combinator . -4))        ; 组合器
  "CSS token类型映射表。")

(defconst css-word-delimiters
  (let ((delims (make-hash-table)))
    (dolist (type '(space tab newline cr feed
                    ampersand asterisk bang comma colon semicolon
                    open-paren close-paren open-square close-square
                    single-quote double-quote plus pipe tilde
                    greater-than equals dollar caret slash))
      (puthash (cdr (assq type css-token-types)) t delims))
    delims)
  "单词分隔符集合。")

(defconst css-whitespace-tokens
  (let ((tokens (make-hash-table)))
    (dolist (type '(space tab newline cr feed))
      (puthash (cdr (assq type css-token-types)) t tokens))
    tokens)
  "空白字符token集合。")

(defconst css-hex-chars
  (let ((hex (make-hash-table)))
    (dolist (char '(?0 ?1 ?2 ?3 ?4 ?5 ?6 ?7 ?8 ?9
                    ?a ?b ?c ?d ?e ?f ?A ?B ?C ?D ?E ?F))
      (puthash char t hex))
    hex)
  "十六进制字符集合。")

;;; 词法分析器（Tokenizer）

(defun css-consume-escape (css start)
  "从CSS字符串中消费一个转义序列。
CSS是输入字符串，START是反斜杠的位置。
返回转义序列的结束位置。"
  (let ((next start)
        (code (and (< (1+ start) (length css))
                   (aref css (1+ start)))))
    (when code
      (if (gethash code css-hex-chars)
          ;; 十六进制转义
          (let ((hex-digits 0))
            (while (and (< hex-digits 6)
                        (< (1+ next) (length css))
                        (gethash (aref css (1+ next)) css-hex-chars))
              (cl-incf next)
              (cl-incf hex-digits))
            ;; 如果少于6个十六进制字符，空格结束转义
            (when (and (< hex-digits 6)
                       (< (1+ next) (length css))
                       (= (aref css (1+ next))
                          (cdr (assq 'space css-token-types))))
              (cl-incf next)))
        ;; 单字符转义
        (cl-incf next)))
    next))

(defun css-consume-word (css start)
  "从CSS字符串中消费一个单词。
CSS是输入字符串，START是单词的起始位置。
返回单词的结束位置。"
  (let ((next start)
        (code nil))
    (while (< next (length css))
      (setq code (aref css next))
      (cond
       ((gethash code css-word-delimiters)
        (cl-return (1- next)))
       ((= code (cdr (assq 'backslash css-token-types)))
        (setq next (1+ (css-consume-escape css next))))
       (t
        (cl-incf next))))
    (1- next)))

(defun css-tokenize (css-string)
  "对CSS选择器字符串进行词法分析。
返回token列表，每个token是一个向量：
[TYPE START-LINE START-COL END-LINE END-COL START-POS END-POS]"
  (let* ((css css-string)
         (length (length css))
         (tokens '())
         (offset -1)
         (line 1)
         (start 0)
         (end 0)
         code content end-column end-line
         escaped escape-pos last lines
         next next-line next-offset quote token-type)
    
    (while (< start length)
      (setq code (aref css start))
      
      ;; 更新行号
      (when (= code (cdr (assq 'newline css-token-types)))
        (setq offset start
              line (1+ line)))
      
      (cond
       ;; 空白字符
       ((memq code (mapcar (lambda (type)
                             (cdr (assq type css-token-types)))
                           '(space tab newline cr feed)))
        (setq next start)
        (while (and (< (cl-incf next) length)
                    (memq (aref css next)
                          (mapcar (lambda (type)
                                    (cdr (assq type css-token-types)))
                                  '(space tab newline cr feed))))
          (when (= (aref css next) (cdr (assq 'newline css-token-types)))
            (setq offset next
                  line (1+ line))))
        (setq token-type (cdr (assq 'space css-token-types))
              end-line line
              end-column (- next offset 1)
              end next))
       
       ;; 组合器: + > ~ |
       ((memq code (mapcar (lambda (type)
                             (cdr (assq type css-token-types)))
                           '(plus greater-than tilde pipe)))
        (setq next start)
        (while (and (< (cl-incf next) length)
                    (memq (aref css next)
                          (mapcar (lambda (type)
                                    (cdr (assq type css-token-types)))
                                  '(plus greater-than tilde pipe)))))
        (setq token-type (cdr (assq 'combinator css-token-types))
              end-line line
              end-column (- start offset)
              end next))
       
       ;; 单字符token
       ((memq code (mapcar (lambda (type)
                             (cdr (assq type css-token-types)))
                           '(asterisk ampersand bang comma equals dollar caret
                             open-square close-square colon semicolon
                             open-paren close-paren)))
        (setq next start
              token-type code
              end-line line
              end-column (- start offset)
              end (1+ next)))
       
       ;; 字符串
       ((memq code (mapcar (lambda (type)
                             (cdr (assq type css-token-types)))
                           '(single-quote double-quote)))
        (setq quote (if (= code (cdr (assq 'single-quote css-token-types)))
                        "'" "\"")
              next start
              escaped nil)
        (catch 'done
          (while t
            (setq next (string-match-p (regexp-quote quote) css (1+ next)))
            (unless next
              (error "Unclosed quote"))
            (setq escape-pos next
                  escaped nil)
            (while (and (> escape-pos 0)
                        (= (aref css (1- escape-pos))
                           (cdr (assq 'backslash css-token-types))))
              (cl-decf escape-pos)
              (setq escaped (not escaped)))
            (unless escaped
              (throw 'done nil))))
        (setq token-type (cdr (assq 'str css-token-types))
              end-line line
              end-column (- start offset)
              end (1+ next)))
       
       ;; 注释或斜杠
       ((= code (cdr (assq 'slash css-token-types)))
        (if (and (< (1+ start) length)
                 (= (aref css (1+ start))
                    (cdr (assq 'asterisk css-token-types))))
            ;; 注释
            (progn
              (setq next (string-match-p "\\*/" css (+ start 2)))
              (unless next
                (error "Unclosed comment"))
              (setq content (substring css start (+ next 2))
                    lines (split-string content "\n" t)
                    last (1- (length lines)))
              (when (> last 0)
                (setq next-line (+ line last)
                      next-offset (- (+ next 1) (length (nth last lines))))
                (setq next-line line
                      next-offset offset))
              (setq token-type (cdr (assq 'comment css-token-types))
                    line next-line
                    end-line next-line
                    end-column (- (1+ next) next-offset)
                    end (+ next 2)))
          ;; 单独的斜杠
          (setq next start
                token-type code
                end-line line
                end-column (- start offset)
                end (1+ next))))
       
       ;; 单词
       (t
        (setq next (css-consume-word css start)
              token-type (cdr (assq 'word css-token-types))
              end-line line
              end-column (- next offset)
              end (1+ next))))
      
      ;; 添加token
      (push (vector token-type line (- start offset) end-line end-column start end)
            tokens)
      
      ;; 重置offset
      (when next-offset
        (setq offset next-offset
              next-offset nil))
      
      (setq start end))
    
    (nreverse tokens)))

;;; AST节点类型

(defconst css-node-types
  '(root selector tag class id attribute pseudo
    universal combinator nesting comment string)
  "CSS AST节点类型列表。")

;;; 节点构造函数

(defun css-make-node (type &rest props)
  "创建一个CSS AST节点。
TYPE是节点类型，PROPS是属性列表。"
  (let ((node (list :type type)))
    (while props
      (setq node (plist-put node (car props) (cadr props))
            props (cddr props)))
    (unless (plist-get node :spaces)
      (setq node (plist-put node :spaces '(:before "" :after ""))))
    node))

(defun css-make-root (&rest props)
  "创建根节点。"
  (apply #'css-make-node 'root :nodes '() props))

(defun css-make-selector (&rest props)
  "创建选择器节点。"
  (apply #'css-make-node 'selector :nodes '() props))

(defun css-make-tag (value &rest props)
  "创建标签选择器节点。"
  (apply #'css-make-node 'tag :value value props))

(defun css-make-class (value &rest props)
  "创建类选择器节点。"
  (apply #'css-make-node 'class :value value props))

(defun css-make-id (value &rest props)
  "创建ID选择器节点。"
  (apply #'css-make-node 'id :value value props))

(defun css-make-attribute (&rest props)
  "创建属性选择器节点。"
  (apply #'css-make-node 'attribute props))

(defun css-make-pseudo (value &rest props)
  "创建伪类/伪元素节点。"
  (apply #'css-make-node 'pseudo :value value props))

(defun css-make-universal (&rest props)
  "创建通配符选择器节点。"
  (apply #'css-make-node 'universal :value "*" props))

(defun css-make-combinator (value &rest props)
  "创建组合器节点。"
  (apply #'css-make-node 'combinator :value value props))

(defun css-make-nesting (&rest props)
  "创建嵌套选择器节点。"
  (apply #'css-make-node 'nesting :value "&" props))

(defun css-make-comment (value &rest props)
  "创建注释节点。"
  (apply #'css-make-node 'comment :value value props))

;;; 节点操作函数

(defun css-node-append (container node)
  "将节点NODE添加到容器CONTAINER的子节点列表中。"
  (let ((nodes (plist-get container :nodes)))
    (plist-put container :nodes (append nodes (list node)))))

(defun css-node-to-string (node)
  "将节点转换为字符串。"
  (let ((type (plist-get node :type))
        (value (plist-get node :value))
        (spaces (plist-get node :spaces))
        (nodes (plist-get node :nodes)))
    (concat
     (or (plist-get spaces :before) "")
     (cond
      ((eq type 'root)
       (mapconcat #'css-node-to-string nodes ","))
      ((eq type 'selector)
       (mapconcat #'css-node-to-string nodes ""))
      ((eq type 'tag) value)
      ((eq type 'class) (concat "." value))
      ((eq type 'id) (concat "#" value))
      ((eq type 'universal) "*")
      ((eq type 'combinator) value)
      ((eq type 'pseudo) value)
      ((eq type 'nesting) "&")
      ((eq type 'comment) value)
      ((eq type 'attribute)
       (let ((attr (plist-get node :attribute))
             (op (plist-get node :operator))
             (val (plist-get node :value))
             (quote (plist-get node :quote-mark)))
         (concat "["
                 (or attr "")
                 (or op "")
                 (when val
                   (if quote
                       (concat quote val quote)
                     val))
                 "]")))
      (t (or value "")))
     (or (plist-get spaces :after) ""))))

;;; 语法分析器（Parser）

(cl-defstruct css-parser
  "CSS解析器结构。"
  css             ; 输入CSS字符串
  tokens          ; token数组
  position        ; 当前位置
  root            ; 根节点
  current)        ; 当前选择器节点

(defun css-parser-curr-token (parser)
  "获取解析器的当前token。"
  (let ((pos (css-parser-position parser)))
    (when (< pos (length (css-parser-tokens parser)))
      (aref (css-parser-tokens parser) pos))))

(defun css-parser-next-token (parser)
  "获取解析器的下一个token。"
  (let ((pos (1+ (css-parser-position parser))))
    (when (< pos (length (css-parser-tokens parser)))
      (aref (css-parser-tokens parser) pos))))

(defun css-parser-content (parser &optional token)
  "获取token的内容字符串。"
  (let ((tok (or token (css-parser-curr-token parser))))
    (when tok
      (substring (css-parser-css parser)
                 (aref tok 5)  ; START-POS
                 (aref tok 6)))))  ; END-POS

(defun css-parser-new-node (parser node)
  "添加新节点到当前选择器。"
  (css-node-append (css-parser-current parser) node)
  node)

(defun css-parser-space (parser)
  "处理空白字符。"
  ;; 简化实现：直接跳过空白
  (cl-incf (css-parser-position parser)))

(defun css-parser-comment (parser)
  "处理注释。"
  (let* ((token (css-parser-curr-token parser))
         (content (css-parser-content parser token)))
    (css-parser-new-node
     parser
     (css-make-comment content))
    (cl-incf (css-parser-position parser))))

(defun css-parser-comma (parser)
  "处理逗号（新选择器）。"
  (let ((selector (css-make-selector)))
    (css-node-append (css-parser-root parser) selector)
    (setf (css-parser-current parser) selector))
  (cl-incf (css-parser-position parser)))

(defun css-parser-word (parser)
  "处理单词token。"
  (let* ((content (css-parser-content parser))
         (i 0)
         (len (length content))
         nodes)
    ;; 分割单词为多个节点
    (while (< i len)
      (let ((ch (aref content i)))
        (cond
         ((= ch ?.)  ; 类选择器
          (let ((start (cl-incf i))
                (end i))
            (while (and (< end len)
                        (not (memq (aref content end) '(?. ?# ?\[))))
              (cl-incf end))
            (push (css-make-class (substring content start end)) nodes)
            (setq i end)))
         
         ((= ch ?#)  ; ID选择器
          (let ((start (cl-incf i))
                (end i))
            (while (and (< end len)
                        (not (memq (aref content end) '(?. ?# ?\[))))
              (cl-incf end))
            (push (css-make-id (substring content start end)) nodes)
            (setq i end)))
         
         (t  ; 标签选择器
          (let ((start i)
                (end i))
            (while (and (< end len)
                        (not (memq (aref content end) '(?. ?# ?\[))))
              (cl-incf end))
            (when (> end start)
              (push (css-make-tag (substring content start end)) nodes))
            (setq i end))))))
    
    ;; 添加节点
    (dolist (node (nreverse nodes))
      (css-parser-new-node parser node))
    (cl-incf (css-parser-position parser))))

(defun css-parser-universal (parser)
  "处理通配符选择器。"
  (css-parser-new-node parser (css-make-universal))
  (cl-incf (css-parser-position parser)))

(defun css-parser-pseudo (parser)
  "处理伪类/伪元素。"
  (let ((content (css-parser-content parser))
        (next (css-parser-next-token parser)))
    ;; 检查是否为双冒号
    (when (and next
               (= (aref next 0) (cdr (assq 'colon css-token-types))))
      (setq content (concat content (css-parser-content parser next)))
      (cl-incf (css-parser-position parser)))
    
    (css-parser-new-node parser (css-make-pseudo content))
    (cl-incf (css-parser-position parser))))

(defun css-parser-combinator (parser)
  "处理组合器。"
  (let ((content (css-parser-content parser)))
    (css-parser-new-node
     parser
     (css-make-combinator (if (string-match-p "^[ \t\n\r\f]+$" content)
                              " "
                            content)))
    (cl-incf (css-parser-position parser))))

(defun css-parser-nesting (parser)
  "处理嵌套选择器。"
  (css-parser-new-node parser (css-make-nesting))
  (cl-incf (css-parser-position parser)))

(defun css-parser-attribute (parser)
  "处理属性选择器。"
  (let ((attr-tokens '())
        (start-token (css-parser-curr-token parser)))
    (cl-incf (css-parser-position parser))
    
    ;; 收集方括号内的token
    (while (and (< (css-parser-position parser)
                   (length (css-parser-tokens parser)))
                (not (= (aref (css-parser-curr-token parser) 0)
                        (cdr (assq 'close-square css-token-types)))))
      (push (css-parser-curr-token parser) attr-tokens)
      (cl-incf (css-parser-position parser)))
    
    (setq attr-tokens (nreverse attr-tokens))
    
    ;; 简化实现：只处理基本属性选择器 [attr] 和 [attr="value"]
    (let ((node (css-make-attribute))
          (pos 0)
          (len (length attr-tokens)))
      
      (when (> len 0)
        ;; 第一个应该是属性名
        (let ((token (nth pos attr-tokens)))
          (when (= (aref token 0) (cdr (assq 'word css-token-types)))
            (plist-put node :attribute (css-parser-content parser token))
            (cl-incf pos)))
        
        ;; 检查操作符
        (when (< pos len)
          (let ((token (nth pos attr-tokens)))
            (when (memq (aref token 0)
                        (mapcar (lambda (type)
                                  (cdr (assq type css-token-types)))
                                '(equals caret dollar asterisk tilde pipe)))
              (let ((op-content (css-parser-content parser token)))
                ;; 检查是否有后续的等号
                (when (and (< (1+ pos) len)
                           (= (aref (nth (1+ pos) attr-tokens) 0)
                              (cdr (assq 'equals css-token-types))))
                  (setq op-content (concat op-content "="))
                  (cl-incf pos))
                (plist-put node :operator op-content)
                (cl-incf pos)))))
        
        ;; 检查值
        (when (< pos len)
          (let ((token (nth pos attr-tokens)))
            (cond
             ((= (aref token 0) (cdr (assq 'str css-token-types)))
              (let ((content (css-parser-content parser token)))
                (plist-put node :value (substring content 1 (1- (length content))))
                (plist-put node :quote-mark (substring content 0 1))))
             ((= (aref token 0) (cdr (assq 'word css-token-types)))
              (plist-put node :value (css-parser-content parser token)))))))
      
      (css-parser-new-node parser node))
    (cl-incf (css-parser-position parser))))

(defun css-parser-parse (parser)
  "解析当前token。"
  (let ((token (css-parser-curr-token parser)))
    (when token
      (let ((type (aref token 0)))
        (cond
         ((gethash type css-whitespace-tokens)
          (css-parser-space parser))
         ((= type (cdr (assq 'comment css-token-types)))
          (css-parser-comment parser))
         ((= type (cdr (assq 'comma css-token-types)))
          (css-parser-comma parser))
         ((= type (cdr (assq 'word css-token-types)))
          (css-parser-word parser))
         ((= type (cdr (assq 'asterisk css-token-types)))
          (css-parser-universal parser))
         ((= type (cdr (assq 'colon css-token-types)))
          (css-parser-pseudo parser))
         ((= type (cdr (assq 'combinator css-token-types)))
          (css-parser-combinator parser))
         ((= type (cdr (assq 'ampersand css-token-types)))
          (css-parser-nesting parser))
         ((= type (cdr (assq 'open-square css-token-types)))
          (css-parser-attribute parser))
         (t
          (cl-incf (css-parser-position parser))))))))

(defun css-parser-loop (parser)
  "主解析循环。"
  (while (< (css-parser-position parser)
            (length (css-parser-tokens parser)))
    (css-parser-parse parser))
  (css-parser-root parser))

;;; 公共API

(defun css-selector-parse (selector-string)
  "解析CSS选择器字符串，返回AST。
SELECTOR-STRING是要解析的CSS选择器字符串。

示例：
  (css-selector-parse \"div.class#id\")
  ;; => AST树结构"
  (let* ((tokens (css-tokenize selector-string))
         (root (css-make-root))
         (selector (css-make-selector))
         (parser nil))
    (css-node-append root selector)
    (setq parser (make-css-parser
                  :css selector-string
                  :tokens (vconcat tokens)
                  :position 0
                  :root root
                  :current selector))
    (css-parser-loop parser)))

(defun css-selector-walk (ast func)
  "遍历AST树的所有节点，对每个节点调用FUNC。
AST是要遍历的抽象语法树，FUNC是对每个节点调用的函数。

示例：
  (css-selector-walk ast
    (lambda (node)
      (message \"Node type: %s\" (plist-get node :type))))"
  (funcall func ast)
  (let ((nodes (plist-get ast :nodes)))
    (when nodes
      (dolist (node nodes)
        (css-selector-walk node func)))))

(defun css-selector-walk-type (ast node-type func)
  "遍历AST树中指定类型的节点，对每个节点调用FUNC。
AST是要遍历的抽象语法树，NODE-TYPE是要匹配的节点类型，
FUNC是对匹配节点调用的函数。

示例：
  (css-selector-walk-type ast 'class
    (lambda (node)
      (message \"Class: %s\" (plist-get node :value))))"
  (css-selector-walk ast
                     (lambda (node)
                       (when (eq (plist-get node :type) node-type)
                         (funcall func node)))))

(defun css-selector-stringify (ast)
  "将AST转换回CSS选择器字符串。
AST是要转换的抽象语法树。

示例：
  (css-selector-stringify (css-selector-parse \"div.class\"))
  ;; => \"div.class\""
  (css-node-to-string ast))

;;; 便捷函数

(defun css-selector-walk-tags (ast func)
  "遍历AST中的所有标签选择器。"
  (css-selector-walk-type ast 'tag func))

(defun css-selector-walk-classes (ast func)
  "遍历AST中的所有类选择器。"
  (css-selector-walk-type ast 'class func))

(defun css-selector-walk-ids (ast func)
  "遍历AST中的所有ID选择器。"
  (css-selector-walk-type ast 'id func))

(defun css-selector-walk-pseudos (ast func)
  "遍历AST中的所有伪类/伪元素。"
  (css-selector-walk-type ast 'pseudo func))

(defun css-selector-walk-attributes (ast func)
  "遍历AST中的所有属性选择器。"
  (css-selector-walk-type ast 'attribute func))

;;; 示例和测试

(defun css-selector-parser-examples ()
  "显示CSS选择器解析器的使用示例。"
  (interactive)
  (with-output-to-temp-buffer "*CSS Selector Parser Examples*"
    (princ "CSS选择器解析器示例\n")
    (princ "====================\n\n")
    
    ;; 示例1：简单选择器
    (princ "示例1：解析简单选择器\n")
    (princ "输入: \"div.class#id\"\n")
    (let ((ast (css-selector-parse "div.class#id")))
      (princ (format "输出: %S\n\n" ast)))
    
    ;; 示例2：组合选择器
    (princ "示例2：解析组合选择器\n")
    (princ "输入: \"div > span + a\"\n")
    (let ((ast (css-selector-parse "div > span + a")))
      (princ (format "输出: %S\n\n" ast)))
    
    ;; 示例3：伪类
    (princ "示例3：解析伪类\n")
    (princ "输入: \"a:hover\"\n")
    (let ((ast (css-selector-parse "a:hover")))
      (princ (format "输出: %S\n\n" ast)))
    
    ;; 示例4：属性选择器
    (princ "示例4：解析属性选择器\n")
    (princ "输入: \"[href]\"\n")
    (let ((ast (css-selector-parse "[href]")))
      (princ (format "输出: %S\n\n" ast)))
    
    ;; 示例5：遍历节点
    (princ "示例5：遍历节点\n")
    (princ "输入: \"div.class#id\"\n")
    (princ "遍历所有节点类型：\n")
    (let ((ast (css-selector-parse "div.class#id"))
          (types '()))
      (css-selector-walk ast
                         (lambda (node)
                           (push (plist-get node :type) types)))
      (princ (format "节点类型: %S\n\n" (nreverse types))))
    
    ;; 示例6：字符串化
    (princ "示例6：AST转字符串\n")
    (princ "输入AST: (从 \"div.class\" 解析)\n")
    (let* ((ast (css-selector-parse "div.class"))
           (str (css-selector-stringify ast)))
      (princ (format "输出: \"%s\"\n\n" str)))
    
    (princ "更多功能请参考函数文档。\n")))

(provide 'css-selector-parser)

;;; css-selector-parser.el ends here

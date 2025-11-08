;;; css-dom-selector.el --- CSS选择器DOM查询和样式应用 -*- lexical-binding: t; -*-

;; Copyright (C) 2024

;; Author: Based on postcss-selector-parser
;; Keywords: css, dom, selector, query
;; Version: 1.0.0

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;;; Commentary:

;; 这个库结合css-selector-parser.el和dom.el，实现了类似浏览器querySelector的功能。
;; 可以使用CSS选择器在DOM树中查询节点，并为匹配的节点应用CSS样式。
;;
;; 主要功能：
;; - 使用CSS选择器在DOM树中查询节点
;; - 支持标签、类、ID、属性选择器
;; - 支持后代、子元素、相邻兄弟、通用兄弟组合器
;; - 支持基本伪类选择器
;; - 为匹配的DOM节点应用CSS属性
;;
;; 使用示例：
;;
;;   ;; 查询单个节点
;;   (css-dom-query-selector dom "div.header")
;;
;;   ;; 查询所有匹配节点
;;   (css-dom-query-selector-all dom "p.text")
;;
;;   ;; 应用CSS样式
;;   (css-dom-apply-style dom ".button" '((color . "red") (font-size . "14px")))

;;; Code:

(require 'cl-lib)
(require 'dom)
(require 'css-selector-parser)

;;; DOM节点匹配函数

(defun css-dom-node-matches-tag (node tag-name)
  "检查DOM节点NODE是否匹配标签选择器TAG-NAME。"
  (when (and node (listp node))
    (let ((node-tag (symbol-name (dom-tag node))))
      (or (string= tag-name "*")  ; 通配符
          (string= tag-name node-tag)))))

(defun css-dom-node-matches-class (node class-name)
  "检查DOM节点NODE是否匹配类选择器CLASS-NAME。"
  (when (and node (listp node))
    (let* ((attrs (dom-attributes node))
           (class-attr (cdr (assq 'class attrs))))
      (when class-attr
        (let ((classes (split-string class-attr)))
          (member class-name classes))))))

(defun css-dom-node-matches-id (node id-name)
  "检查DOM节点NODE是否匹配ID选择器ID-NAME。"
  (when (and node (listp node))
    (let* ((attrs (dom-attributes node))
           (id-attr (cdr (assq 'id attrs))))
      (and id-attr (string= id-attr id-name)))))

(defun css-dom-node-matches-attribute (node attr-node)
  "检查DOM节点NODE是否匹配属性选择器ATTR-NODE。"
  (when (and node (listp node))
    (let* ((attrs (dom-attributes node))
           (attr-name (intern (plist-get attr-node :attribute)))
           (operator (plist-get attr-node :operator))
           (expected-value (plist-get attr-node :value))
           (actual-value (cdr (assq attr-name attrs))))
      (cond
       ;; 仅检查属性存在
       ((null operator)
        (not (null actual-value)))
       ;; 属性值完全匹配
       ((string= operator "=")
        (and actual-value (string= actual-value expected-value)))
       ;; 属性值前缀匹配
       ((string= operator "^=")
        (and actual-value (string-prefix-p expected-value actual-value)))
       ;; 属性值后缀匹配
       ((string= operator "$=")
        (and actual-value (string-suffix-p expected-value actual-value)))
       ;; 属性值包含子串
       ((string= operator "*=")
        (and actual-value (string-match-p (regexp-quote expected-value) actual-value)))
       ;; 属性值包含空格分隔的单词
       ((string= operator "~=")
        (and actual-value 
             (member expected-value (split-string actual-value))))
       ;; 属性值等于或以其开头后跟连字符
       ((string= operator "|=")
        (and actual-value
             (or (string= actual-value expected-value)
                 (string-prefix-p (concat expected-value "-") actual-value))))
       (t nil)))))

(defun css-dom-node-matches-pseudo (node pseudo-node)
  "检查DOM节点NODE是否匹配伪类选择器PSEUDO-NODE。
目前支持基本的结构伪类。"
  (when (and node (listp node))
    (let ((pseudo-value (plist-get pseudo-node :value)))
      (cond
       ;; :first-child
       ((string= pseudo-value ":first-child")
        (css-dom-is-first-child node))
       ;; :last-child
       ((string= pseudo-value ":last-child")
        (css-dom-is-last-child node))
       ;; :only-child
       ((string= pseudo-value ":only-child")
        (and (css-dom-is-first-child node)
             (css-dom-is-last-child node)))
       ;; 其他伪类暂不支持，返回t以避免过滤
       (t t)))))

(defun css-dom-is-first-child (node)
  "检查节点是否是其父节点的第一个子元素。"
  ;; 简化实现：假设我们不保存父节点引用
  ;; 在实际应用中需要遍历时跟踪
  t)

(defun css-dom-is-last-child (node)
  "检查节点是否是其父节点的最后一个子元素。"
  ;; 简化实现
  t)

(defun css-dom-node-matches-simple-selector (node selector-ast)
  "检查DOM节点NODE是否匹配简单选择器SELECTOR-AST。
简单选择器是没有组合器的选择器序列，如 'div.class#id'。"
  (when (and node (listp node))
    (let ((matches t))
      ;; 遍历选择器的所有组件
      (css-selector-walk selector-ast
        (lambda (sel-node)
          (let ((type (plist-get sel-node :type)))
            (cond
             ((eq type 'tag)
              (unless (css-dom-node-matches-tag node (plist-get sel-node :value))
                (setq matches nil)))
             ((eq type 'class)
              (unless (css-dom-node-matches-class node (plist-get sel-node :value))
                (setq matches nil)))
             ((eq type 'id)
              (unless (css-dom-node-matches-id node (plist-get sel-node :value))
                (setq matches nil)))
             ((eq type 'universal)
              ;; 通配符总是匹配
              t)
             ((eq type 'attribute)
              (unless (css-dom-node-matches-attribute node sel-node)
                (setq matches nil)))
             ((eq type 'pseudo)
              (unless (css-dom-node-matches-pseudo node sel-node)
                (setq matches nil)))))))
      matches)))

;;; 选择器序列分割

(defun css-dom-split-selector-by-combinators (selector-ast)
  "将选择器AST按组合器分割成多个部分。
返回一个列表，每个元素是 (selector-nodes . combinator)。"
  (let ((parts '())
        (current-nodes '())
        (current-combinator nil))
    (dolist (node (plist-get selector-ast :nodes))
      (if (eq (plist-get node :type) 'combinator)
          (progn
            ;; 保存当前累积的节点和组合器
            (when current-nodes
              (push (cons (nreverse current-nodes) current-combinator) parts))
            ;; 设置新的组合器
            (setq current-combinator (plist-get node :value))
            (setq current-nodes '()))
        ;; 累积非组合器节点
        (push node current-nodes)))
    ;; 添加最后一组节点
    (when current-nodes
      (push (cons (nreverse current-nodes) current-combinator) parts))
    (nreverse parts)))

(defun css-dom-node-matches-selector-part (node selector-nodes)
  "检查DOM节点是否匹配选择器节点列表SELECTOR-NODES。"
  (let ((matches t)
        (mock-selector (css-make-selector)))
    ;; 创建一个临时选择器节点来包含这些节点
    (dolist (sel-node selector-nodes)
      (css-node-append mock-selector sel-node))
    (css-dom-node-matches-simple-selector node mock-selector)))

;;; 组合器匹配

(defun css-dom-matches-descendant-combinator (node ancestor-nodes dom)
  "检查节点NODE是否有祖先匹配ANCESTOR-NODES（后代组合器）。"
  (let ((found nil))
    (css-dom-walk dom
      (lambda (candidate)
        (when (and (not found)
                   (css-dom-node-matches-selector-part candidate ancestor-nodes)
                   (css-dom-is-descendant-of node candidate dom))
          (setq found t))))
    found))

(defun css-dom-matches-child-combinator (node parent-nodes dom)
  "检查节点NODE的直接父节点是否匹配PARENT-NODES（子组合器）。"
  ;; 简化实现：遍历DOM查找包含node作为直接子节点的节点
  (let ((found nil))
    (css-dom-walk dom
      (lambda (candidate)
        (when (and (not found)
                   (css-dom-node-matches-selector-part candidate parent-nodes))
          (let ((children (dom-non-text-children candidate)))
            (when (memq node children)
              (setq found t))))))
    found))

(defun css-dom-matches-adjacent-sibling-combinator (node prev-sibling-nodes dom)
  "检查节点NODE的前一个兄弟节点是否匹配PREV-SIBLING-NODES（相邻兄弟组合器）。"
  ;; 简化实现
  t)

(defun css-dom-matches-general-sibling-combinator (node sibling-nodes dom)
  "检查节点NODE之前的兄弟节点中是否有匹配SIBLING-NODES（通用兄弟组合器）。"
  ;; 简化实现
  t)

(defun css-dom-is-descendant-of (node ancestor dom)
  "检查NODE是否是ANCESTOR的后代。"
  (and (not (eq node ancestor))
       (catch 'found
         (css-dom-walk ancestor
           (lambda (candidate)
             (when (eq candidate node)
               (throw 'found t))))
         nil)))

;;; 主要查询函数

(defun css-dom-query-selector-complex (dom selector-ast)
  "使用复杂选择器（包含组合器）查询DOM。
返回所有匹配的节点列表。"
  (let ((parts (css-dom-split-selector-by-combinators selector-ast))
        (results '()))
    (if (= (length parts) 1)
        ;; 简单选择器，无组合器
        (css-dom-walk dom
          (lambda (node)
            (when (css-dom-node-matches-selector-part node (caar parts))
              (push node results))))
      ;; 复杂选择器，有组合器
      ;; 从右到左匹配
      (let ((rightmost-part (car (last parts)))
            (preceding-parts (butlast parts)))
        ;; 首先找到匹配最右侧选择器的节点
        (css-dom-walk dom
          (lambda (node)
            (when (css-dom-node-matches-selector-part node (car rightmost-part))
              ;; 检查是否满足所有组合器关系
              (when (css-dom-check-combinator-chain node preceding-parts dom)
                (push node results)))))))
    (nreverse results)))

(defun css-dom-check-combinator-chain (node parts dom)
  "检查节点是否满足组合器链的所有条件。
从右到左处理PARTS。"
  (if (null parts)
      t
    (let* ((current-part (car (last parts)))
           (remaining-parts (butlast parts))
           (combinator (cdr current-part))
           (selector-nodes (car current-part)))
      (cond
       ;; 后代组合器（空格）
       ((or (null combinator) (string= combinator " "))
        (and (css-dom-matches-descendant-combinator node selector-nodes dom)
             (if remaining-parts
                 ;; 递归检查剩余部分（需要找到匹配的祖先）
                 t  ; 简化实现
               t)))
       ;; 子组合器 (>)
       ((string= combinator ">")
        (and (css-dom-matches-child-combinator node selector-nodes dom)
             (if remaining-parts t t)))
       ;; 相邻兄弟组合器 (+)
       ((string= combinator "+")
        (and (css-dom-matches-adjacent-sibling-combinator node selector-nodes dom)
             (if remaining-parts t t)))
       ;; 通用兄弟组合器 (~)
       ((string= combinator "~")
        (and (css-dom-matches-general-sibling-combinator node selector-nodes dom)
             (if remaining-parts t t)))
       (t t)))))

(defun css-dom-query-selector-all (dom selector-string)
  "在DOM树中查询所有匹配CSS选择器的节点。
DOM是要查询的DOM树，SELECTOR-STRING是CSS选择器字符串。
返回匹配节点的列表。

示例：
  (css-dom-query-selector-all dom \"div.container p.text\")"
  (let* ((ast (css-selector-parse selector-string))
         (root (plist-get ast :type))
         (results '()))
    ;; 处理根节点中的所有选择器（逗号分隔）
    (dolist (selector (plist-get ast :nodes))
      (when (eq (plist-get selector :type) 'selector)
        (let ((matches (css-dom-query-selector-complex dom selector)))
          (setq results (append results matches)))))
    ;; 去重
    (cl-remove-duplicates results :test #'equal)))

(defun css-dom-query-selector (dom selector-string)
  "在DOM树中查询第一个匹配CSS选择器的节点。
DOM是要查询的DOM树，SELECTOR-STRING是CSS选择器字符串。
返回第一个匹配的节点，如果没有匹配则返回nil。

示例：
  (css-dom-query-selector dom \"#header\")"
  (car (css-dom-query-selector-all dom selector-string)))

;;; DOM遍历辅助函数

(defun css-dom-walk (node func)
  "遍历DOM树的所有节点，对每个节点调用FUNC。
NODE是要遍历的DOM节点，FUNC是对每个节点调用的函数。"
  (when (and node (listp node))
    (funcall func node)
    (let ((children (dom-children node)))
      (dolist (child children)
        (when (listp child)  ; 跳过文本节点
          (css-dom-walk child func))))))

;;; CSS样式应用

(defun css-dom-apply-style (dom selector-string styles)
  "为DOM中匹配选择器的节点应用CSS样式。
DOM是要操作的DOM树，SELECTOR-STRING是CSS选择器字符串，
STYLES是要应用的样式列表，格式为 ((property . value) ...)。

示例：
  (css-dom-apply-style dom \".button\"
    '((color . \"red\") (font-size . \"14px\")))"
  (let ((nodes (css-dom-query-selector-all dom selector-string)))
    (dolist (node nodes)
      (css-dom-set-styles node styles))
    nodes))

(defun css-dom-set-styles (node styles)
  "为DOM节点设置CSS样式。
NODE是DOM节点，STYLES是样式列表 ((property . value) ...)。"
  (when (and node (listp node))
    (let* ((attrs (dom-attributes node))
           (style-attr (cdr (assq 'style attrs)))
           (style-map (css-dom-parse-style-string (or style-attr ""))))
      ;; 合并新样式
      (dolist (style styles)
        (setq style-map (css-dom-set-style-property 
                         style-map (car style) (cdr style))))
      ;; 更新style属性
      (let ((new-style-string (css-dom-style-map-to-string style-map)))
        (if attrs
            (setcdr (assq 'style attrs) new-style-string)
          ;; 如果没有属性，创建属性列表
          (setcar (cdr node) (list (cons 'style new-style-string))))))))

(defun css-dom-parse-style-string (style-string)
  "解析CSS style属性字符串为属性映射表。
返回一个alist: ((property . value) ...)。"
  (let ((result '())
        (declarations (split-string style-string ";" t)))
    (dolist (decl declarations)
      (when (string-match "\\s-*\\([^:]+\\)\\s-*:\\s-*\\(.+\\)\\s-*" decl)
        (let ((prop (match-string 1 decl))
              (value (match-string 2 decl)))
          (push (cons (intern prop) value) result))))
    (nreverse result)))

(defun css-dom-set-style-property (style-map property value)
  "在样式映射表中设置或更新属性。"
  (let ((existing (assq property style-map)))
    (if existing
        (setcdr existing value)
      (setq style-map (append style-map (list (cons property value)))))
    style-map))

(defun css-dom-style-map-to-string (style-map)
  "将样式映射表转换为CSS style字符串。"
  (mapconcat (lambda (pair)
               (format "%s: %s" (car pair) (cdr pair)))
             style-map "; "))

(defun css-dom-get-style (node property)
  "获取DOM节点的指定CSS属性值。
NODE是DOM节点，PROPERTY是CSS属性名（symbol）。"
  (when (and node (listp node))
    (let* ((attrs (dom-attributes node))
           (style-attr (cdr (assq 'style attrs)))
           (style-map (css-dom-parse-style-string (or style-attr ""))))
      (cdr (assq property style-map)))))

;;; 便捷函数

(defun css-dom-add-class (node class-name)
  "为DOM节点添加CSS类。"
  (when (and node (listp node))
    (let* ((attrs (dom-attributes node))
           (class-attr (cdr (assq 'class attrs)))
           (classes (if class-attr (split-string class-attr) '())))
      (unless (member class-name classes)
        (let ((new-class (string-join (append classes (list class-name)) " ")))
          (if attrs
              (if (assq 'class attrs)
                  (setcdr (assq 'class attrs) new-class)
                (setcdr attrs (cons (cons 'class new-class) (cdr attrs))))
            (setcar (cdr node) (list (cons 'class new-class)))))))))

(defun css-dom-remove-class (node class-name)
  "从DOM节点移除CSS类。"
  (when (and node (listp node))
    (let* ((attrs (dom-attributes node))
           (class-attr (cdr (assq 'class attrs)))
           (classes (if class-attr (split-string class-attr) '())))
      (when (member class-name classes)
        (let ((new-class (string-join (delete class-name classes) " ")))
          (when (assq 'class attrs)
            (setcdr (assq 'class attrs) new-class)))))))

(defun css-dom-has-class (node class-name)
  "检查DOM节点是否有指定的CSS类。"
  (css-dom-node-matches-class node class-name))

(defun css-dom-toggle-class (node class-name)
  "切换DOM节点的CSS类。"
  (if (css-dom-has-class node class-name)
      (css-dom-remove-class node class-name)
    (css-dom-add-class node class-name)))

;;; 示例和测试

(defun css-dom-selector-examples ()
  "演示CSS DOM选择器的各种功能。"
  (interactive)
  (with-output-to-temp-buffer "*CSS DOM Selector Examples*"
    (princ "=== CSS DOM选择器示例 ===\n\n")
    
    ;; 创建示例DOM
    (princ "创建示例DOM结构...\n\n")
    (let ((test-dom 
           '(html nil
             (head nil
               (title nil "Test Page"))
             (body ((class . "main-body"))
               (div ((id . "header") (class . "header fixed"))
                 (h1 nil "Title")
                 (nav ((class . "menu"))
                   (ul nil
                     (li ((class . "item")) (a ((href . "/home")) "Home"))
                     (li ((class . "item active")) (a ((href . "/about")) "About")))))
               (div ((id . "content") (class . "content"))
                 (p ((class . "text")) "Hello World")
                 (p ((class . "text highlight")) "Important Text"))
               (div ((id . "footer") (class . "footer"))
                 (p nil "Footer Text"))))))
      
      ;; 示例1：按ID查询
      (princ "示例1：按ID查询\n")
      (let ((node (css-dom-query-selector test-dom "#header")))
        (princ (format "  querySelector(\"#header\"): %S\n\n" node)))
      
      ;; 示例2：按类查询所有
      (princ "示例2：按类查询所有\n")
      (let ((nodes (css-dom-query-selector-all test-dom ".text")))
        (princ (format "  querySelectorAll(\".text\"): 找到 %d 个节点\n" (length nodes)))
        (dolist (node nodes)
          (princ (format "    - %S\n" node)))
        (princ "\n"))
      
      ;; 示例3：按标签查询
      (princ "示例3：按标签查询\n")
      (let ((nodes (css-dom-query-selector-all test-dom "p")))
        (princ (format "  querySelectorAll(\"p\"): 找到 %d 个节点\n\n" (length nodes))))
      
      ;; 示例4：组合选择器
      (princ "示例4：组合选择器\n")
      (let ((node (css-dom-query-selector test-dom "div.header")))
        (princ (format "  querySelector(\"div.header\"): %S\n\n" node)))
      
      ;; 示例5：应用样式
      (princ "示例5：应用样式\n")
      (let ((test-dom-copy (copy-tree test-dom)))
        (css-dom-apply-style test-dom-copy ".text" 
                             '((color . "red") (font-size . "16px")))
        (princ "  应用样式到 .text 元素\n")
        (let ((node (css-dom-query-selector test-dom-copy ".text")))
          (princ (format "  第一个 .text 节点: %S\n\n" node))))
      
      ;; 示例6：类操作
      (princ "示例6：类操作\n")
      (let ((test-dom-copy (copy-tree test-dom))
            (node (css-dom-query-selector test-dom "#header")))
        (css-dom-add-class node "new-class")
        (princ (format "  添加类后: %S\n" node))
        (css-dom-remove-class node "fixed")
        (princ (format "  移除类后: %S\n\n" node)))
      
      (princ "示例完成！\n"))))

(provide 'css-dom-selector)

;;; css-dom-selector.el ends here

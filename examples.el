;;; examples.el --- CSS选择器解析器示例代码 -*- lexical-binding: t; -*-

;; 这个文件包含了css-selector-parser.el的各种使用示例

(require 'css-selector-parser)

;;; 基础示例

(defun example-1-basic-parsing ()
  "示例1：基本的选择器解析。"
  (message "\n=== 示例1：基本解析 ===")
  
  ;; 简单选择器
  (let ((ast (css-selector-parse "div")))
    (message "解析 'div': %S" ast))
  
  ;; 类选择器
  (let ((ast (css-selector-parse ".button")))
    (message "解析 '.button': %S" ast))
  
  ;; ID选择器
  (let ((ast (css-selector-parse "#header")))
    (message "解析 '#header': %S" ast))
  
  ;; 组合选择器
  (let ((ast (css-selector-parse "div.container#main")))
    (message "解析 'div.container#main': %S" ast)))

(defun example-2-complex-selectors ()
  "示例2：复杂选择器解析。"
  (message "\n=== 示例2：复杂选择器 ===")
  
  ;; 后代选择器
  (let ((ast (css-selector-parse "div span")))
    (message "后代选择器 'div span': %S" ast))
  
  ;; 子元素选择器
  (let ((ast (css-selector-parse "ul > li")))
    (message "子元素选择器 'ul > li': %S" ast))
  
  ;; 相邻兄弟选择器
  (let ((ast (css-selector-parse "h1 + p")))
    (message "相邻兄弟 'h1 + p': %S" ast))
  
  ;; 通用兄弟选择器
  (let ((ast (css-selector-parse "h1 ~ p")))
    (message "通用兄弟 'h1 ~ p': %S" ast)))

(defun example-3-pseudo-selectors ()
  "示例3：伪类和伪元素。"
  (message "\n=== 示例3：伪类和伪元素 ===")
  
  ;; 伪类
  (let ((ast (css-selector-parse "a:hover")))
    (message "伪类 'a:hover': %S" ast))
  
  ;; 伪元素
  (let ((ast (css-selector-parse "p::before")))
    (message "伪元素 'p::before': %S" ast))
  
  ;; 多个伪类
  (let ((ast (css-selector-parse "input:focus:valid")))
    (message "多个伪类 'input:focus:valid': %S" ast)))

(defun example-4-attribute-selectors ()
  "示例4：属性选择器。"
  (message "\n=== 示例4：属性选择器 ===")
  
  ;; 存在属性
  (let ((ast (css-selector-parse "[disabled]")))
    (message "属性存在 '[disabled]': %S" ast))
  
  ;; 属性等于
  (let ((ast (css-selector-parse "[type=\"text\"]")))
    (message "属性等于 '[type=\"text\"]': %S" ast))
  
  ;; 前缀匹配
  (let ((ast (css-selector-parse "[href^=\"https\"]")))
    (message "前缀匹配 '[href^=\"https\"]': %S" ast)))

;;; 遍历示例

(defun example-5-walking-ast ()
  "示例5：遍历AST树。"
  (message "\n=== 示例5：遍历AST ===")
  
  (let ((ast (css-selector-parse "div.container > p.text:first-child")))
    
    ;; 遍历所有节点
    (message "所有节点类型:")
    (css-selector-walk ast
      (lambda (node)
        (message "  - %s" (plist-get node :type))))
    
    ;; 只遍历标签
    (message "\n标签:")
    (css-selector-walk-tags ast
      (lambda (node)
        (message "  - %s" (plist-get node :value))))
    
    ;; 只遍历类
    (message "\n类:")
    (css-selector-walk-classes ast
      (lambda (node)
        (message "  - %s" (plist-get node :value))))))

;;; 实用工具示例

(defun example-6-extract-classes (selector)
  "示例6：提取选择器中的所有类名。"
  (let ((ast (css-selector-parse selector))
        (classes '()))
    (css-selector-walk-classes ast
      (lambda (node)
        (push (plist-get node :value) classes)))
    (nreverse classes)))

(defun example-6-demo ()
  "运行示例6。"
  (message "\n=== 示例6：提取类名 ===")
  (let ((classes (example-6-extract-classes "div.header.fixed > nav.menu ul.items li.item")))
    (message "提取的类名: %S" classes)))

(defun example-7-count-selectors (selector)
  "示例7：统计选择器中各类型的数量。"
  (let ((ast (css-selector-parse selector))
        (counts (list :tags 0 :classes 0 :ids 0 :pseudos 0 :combinators 0)))
    (css-selector-walk ast
      (lambda (node)
        (let ((type (plist-get node :type)))
          (cond
           ((eq type 'tag) 
            (plist-put counts :tags (1+ (plist-get counts :tags))))
           ((eq type 'class) 
            (plist-put counts :classes (1+ (plist-get counts :classes))))
           ((eq type 'id) 
            (plist-put counts :ids (1+ (plist-get counts :ids))))
           ((eq type 'pseudo) 
            (plist-put counts :pseudos (1+ (plist-get counts :pseudos))))
           ((eq type 'combinator) 
            (plist-put counts :combinators (1+ (plist-get counts :combinators))))))))
    counts))

(defun example-7-demo ()
  "运行示例7。"
  (message "\n=== 示例7：统计选择器 ===")
  (let ((stats (example-7-count-selectors "div#main.container > p.text:hover + span")))
    (message "统计结果: %S" stats)))

(defun example-8-add-prefix (selector prefix)
  "示例8：为所有类名添加前缀。"
  (let ((ast (css-selector-parse selector)))
    (css-selector-walk-classes ast
      (lambda (node)
        (let ((old-value (plist-get node :value)))
          (plist-put node :value (concat prefix old-value)))))
    (css-selector-stringify ast)))

(defun example-8-demo ()
  "运行示例8。"
  (message "\n=== 示例8：添加类名前缀 ===")
  (let ((original ".button.large")
        (modified (example-8-add-prefix ".button.large" "my-")))
    (message "原始: %s" original)
    (message "修改: %s" modified)))

(defun example-9-selector-specificity (selector)
  "示例9：计算选择器的特异性（CSS specificity）。
根据CSS规范，特异性计算为 [ID数, 类数+属性数+伪类数, 元素数+伪元素数]"
  (let ((ast (css-selector-parse selector))
        (ids 0)
        (classes 0)
        (elements 0))
    (css-selector-walk ast
      (lambda (node)
        (let ((type (plist-get node :type)))
          (cond
           ((eq type 'id) (cl-incf ids))
           ((memq type '(class attribute pseudo)) (cl-incf classes))
           ((memq type '(tag)) (cl-incf elements))))))
    (list ids classes elements)))

(defun example-9-demo ()
  "运行示例9。"
  (message "\n=== 示例9：计算选择器特异性 ===")
  (let ((selectors '("div"
                     ".button"
                     "#header"
                     "div.container > p.text"
                     "#main .content ul li:hover")))
    (dolist (sel selectors)
      (let ((spec (example-9-selector-specificity sel)))
        (message "%s -> %S" sel spec)))))

(defun example-10-has-pseudo-p (selector)
  "示例10：检查选择器是否包含伪类或伪元素。"
  (let ((ast (css-selector-parse selector))
        (has-pseudo nil))
    (css-selector-walk-pseudos ast
      (lambda (node)
        (setq has-pseudo t)))
    has-pseudo))

(defun example-10-demo ()
  "运行示例10。"
  (message "\n=== 示例10：检查伪类 ===")
  (let ((selectors '("div.button"
                     "a:hover"
                     "p::first-line"
                     "input:focus:valid")))
    (dolist (sel selectors)
      (message "%s 包含伪类? %s" sel (if (example-10-has-pseudo-p sel) "是" "否")))))

(defun example-11-get-tag-names (selector)
  "示例11：获取选择器中的所有标签名。"
  (let ((ast (css-selector-parse selector))
        (tags '()))
    (css-selector-walk-tags ast
      (lambda (node)
        (push (plist-get node :value) tags)))
    (nreverse tags)))

(defun example-11-demo ()
  "运行示例11。"
  (message "\n=== 示例11：提取标签名 ===")
  (let ((tags (example-11-get-tag-names "div.container > ul li.item a:hover")))
    (message "标签列表: %S" tags)))

(defun example-12-selector-complexity (selector)
  "示例12：评估选择器复杂度。
返回一个复杂度分数，分数越高表示选择器越复杂。"
  (let ((ast (css-selector-parse selector))
        (complexity 0))
    (css-selector-walk ast
      (lambda (node)
        (let ((type (plist-get node :type)))
          (cond
           ((eq type 'tag) (cl-incf complexity 1))
           ((eq type 'class) (cl-incf complexity 10))
           ((eq type 'id) (cl-incf complexity 100))
           ((eq type 'attribute) (cl-incf complexity 10))
           ((eq type 'pseudo) (cl-incf complexity 10))
           ((eq type 'combinator) (cl-incf complexity 1))))))
    complexity))

(defun example-12-demo ()
  "运行示例12。"
  (message "\n=== 示例12：选择器复杂度 ===")
  (let ((selectors '("div"
                     ".button"
                     "#header"
                     "div.container"
                     "div#main.container > ul li.item:hover")))
    (dolist (sel selectors)
      (let ((complexity (example-12-selector-complexity sel)))
        (message "%s -> 复杂度: %d" sel complexity)))))

;;; 高级示例

(defun example-13-normalize-selector (selector)
  "示例13：规范化选择器（移除多余空白）。"
  (let ((ast (css-selector-parse selector)))
    ;; 规范化所有节点的空白
    (css-selector-walk ast
      (lambda (node)
        (when (plist-get node :spaces)
          (plist-put (plist-get node :spaces) :before "")
          (plist-put (plist-get node :spaces) :after ""))))
    (css-selector-stringify ast)))

(defun example-13-demo ()
  "运行示例13。"
  (message "\n=== 示例13：规范化选择器 ===")
  (let ((original "div  .class   >   span")
        (normalized (example-13-normalize-selector "div  .class   >   span")))
    (message "原始: '%s'" original)
    (message "规范: '%s'" normalized)))

(defun example-14-selector-to-list (selector)
  "示例14：将选择器转换为易读的列表表示。"
  (let ((ast (css-selector-parse selector))
        (result '()))
    (css-selector-walk ast
      (lambda (node)
        (let ((type (plist-get node :type))
              (value (plist-get node :value)))
          (when (and value (not (memq type '(root selector))))
            (push (cons type value) result)))))
    (nreverse result)))

(defun example-14-demo ()
  "运行示例14。"
  (message "\n=== 示例14：选择器列表表示 ===")
  (let ((list (example-14-selector-to-list "div.container#main > p.text:hover")))
    (message "列表表示:")
    (dolist (item list)
      (message "  %s: %s" (car item) (cdr item)))))

(defun example-15-compare-selectors (sel1 sel2)
  "示例15：比较两个选择器的相似度。
返回0-1之间的值，1表示完全相同。"
  (let ((ast1 (css-selector-parse sel1))
        (ast2 (css-selector-parse sel2))
        (types1 '())
        (types2 '()))
    ;; 收集所有节点类型
    (css-selector-walk ast1
      (lambda (node)
        (push (plist-get node :type) types1)))
    (css-selector-walk ast2
      (lambda (node)
        (push (plist-get node :type) types2)))
    ;; 计算相似度（简化实现）
    (let ((common 0)
          (total (max (length types1) (length types2))))
      (dolist (type types1)
        (when (memq type types2)
          (cl-incf common)))
      (if (> total 0)
          (/ (float common) total)
        0.0))))

(defun example-15-demo ()
  "运行示例15。"
  (message "\n=== 示例15：选择器相似度 ===")
  (let ((pairs '(("div.button" "div.link")
                 ("div > span" "p > span")
                 ("#header" ".header")
                 ("a:hover" "a:focus"))))
    (dolist (pair pairs)
      (let ((sel1 (car pair))
            (sel2 (cadr pair))
            (similarity (example-15-compare-selectors (car pair) (cadr pair))))
        (message "%s vs %s -> %.2f" sel1 sel2 similarity)))))

;;; 运行所有示例

(defun run-all-examples ()
  "运行所有示例。"
  (interactive)
  (message "\n\n===================================")
  (message "CSS选择器解析器示例集")
  (message "===================================")
  
  (example-1-basic-parsing)
  (example-2-complex-selectors)
  (example-3-pseudo-selectors)
  (example-4-attribute-selectors)
  (example-5-walking-ast)
  (example-6-demo)
  (example-7-demo)
  (example-8-demo)
  (example-9-demo)
  (example-10-demo)
  (example-11-demo)
  (example-12-demo)
  (example-13-demo)
  (example-14-demo)
  (example-15-demo)
  
  (message "\n所有示例运行完成！"))

;; 提供一个交互式命令
(defun css-selector-parser-run-examples ()
  "运行CSS选择器解析器的所有示例。
这会在*Messages*缓冲区中显示结果。"
  (interactive)
  (run-all-examples)
  (switch-to-buffer "*Messages*")
  (goto-char (point-max)))

(provide 'examples)

;;; examples.el ends here

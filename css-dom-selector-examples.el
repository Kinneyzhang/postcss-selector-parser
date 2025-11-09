;;; css-dom-selector-examples.el --- CSS DOM选择器示例 -*- lexical-binding: t; -*-

;; 这个文件包含了css-dom-selector.el的各种使用示例

(require 'css-dom-selector)

;;; 示例DOM数据

(defvar example-dom-simple
  '(html nil
    (head nil
      (title nil "Simple Page"))
    (body nil
      (div ((class . "container"))
        (h1 ((id . "title")) "Welcome")
        (p ((class . "text")) "Hello World")
        (p ((class . "text highlight")) "Important Message"))))
  "简单的DOM结构示例。")

(defvar example-dom-complex
  '(html nil
         (head nil
               (title nil "Complex Page")
               (meta ((charset . "utf-8"))))
         (body ((class . "main-body") (data-theme . "light"))
               (header ((id . "header") (class . "header fixed"))
                       (div ((class . "logo")) "Logo")
                       (nav ((class . "navigation"))
                            (ul ((class . "menu"))
                                (li ((class . "menu-item"))
                                    (a ((href . "/")) "Home"))
                                (li ((class . "menu-item active"))
                                    (a ((href . "/about")) "About"))
                                (li ((class . "menu-item"))
                                    (a ((href . "/contact")) "Contact")))))
               (main ((id . "content") (class . "content"))
                     (article ((class . "post"))
                              (h2 ((class . "post-title")) "Article Title")
                              (p ((class . "post-content")) "Article content here...")
                              (div ((class . "tags"))
                                   (span ((class . "tag")) "tag1")
                                   (span ((class . "tag")) "tag2")))
                     (article ((class . "post featured"))
                              (h2 ((class . "post-title")) "Featured Article")
                              (p ((class . "post-content")) "Featured content...")))
               (aside ((id . "sidebar") (class . "sidebar"))
                      (div ((class . "widget"))
                           (h3 nil "Recent Posts")
                           (ul nil
                               (li nil (a ((href . "#")) "Post 1"))
                               (li nil (a ((href . "#")) "Post 2")))))
               (footer ((id . "footer") (class . "footer"))
                       (p ((class . "copyright")) "© 2024"))))
  "复杂的DOM结构示例。")

;;; 基础查询示例

(defun example-dom-1-basic-queries ()
  "示例1：基础查询操作。"
  (message "\n=== 示例1：基础查询 ===")
  
  ;; 按ID查询
  (let ((node (css-dom-query-selector example-dom-simple "#title")))
    (message "按ID查询 #title: %S" (dom-tag node)))
  
  ;; 按类查询
  (let ((nodes (css-dom-query-selector-all example-dom-simple ".text")))
    (message "按类查询 .text: 找到 %d 个节点" (length nodes)))
  
  ;; 按标签查询
  (let ((nodes (css-dom-query-selector-all example-dom-simple "p")))
    (message "按标签查询 p: 找到 %d 个节点" (length nodes)))
  
  ;; 通配符查询
  (let ((nodes (css-dom-query-selector-all example-dom-simple "*")))
    (message "通配符查询 *: 找到 %d 个节点" (length nodes))))

(defun example-dom-2-combined-selectors ()
  "示例2：组合选择器。"
  (message "\n=== 示例2：组合选择器 ===")
  
  ;; 标签+类
  (let ((node (css-dom-query-selector example-dom-simple "p.text")))
    (message "标签+类 p.text: %S" (dom-texts node)))
  
  ;; 标签+ID
  (let ((node (css-dom-query-selector example-dom-simple "h1#title")))
    (message "标签+ID h1#title: %S" (when node (dom-texts node))))
  
  ;; 多个类
  (let ((nodes (css-dom-query-selector-all example-dom-simple ".text.highlight")))
    (message "多个类 .text.highlight: 找到 %d 个节点" (length nodes))))

(defun example-dom-3-descendant-selectors ()
  "示例3：后代选择器。"
  (message "\n=== 示例3：后代选择器 ===")
  
  ;; 后代选择器 - 使用嵌套查询作为替代方案
  (let* ((nav (css-dom-query-selector example-dom-complex "nav"))
         (nodes (when nav (css-dom-query-selector-all nav "a"))))
    (message "后代选择器 'nav a': 找到 %d 个链接" (length nodes)))
  
  ;; 深层后代 - 使用嵌套查询
  (let* ((header (css-dom-query-selector example-dom-complex "header"))
         (ul (when header (css-dom-query-selector header "ul")))
         (nodes (when ul (css-dom-query-selector-all ul "li"))))
    (message "深层后代 'header ul li': 找到 %d 个项" (length nodes)))
  
  ;; 类后代 - 使用嵌套查询
  (let* ((menu (css-dom-query-selector example-dom-complex ".menu"))
         (nodes (when menu (css-dom-query-selector-all menu ".menu-item"))))
    (message "类后代 '.menu .menu-item': 找到 %d 个项" (length nodes))))

(defun example-dom-4-child-selectors ()
  "示例4：子选择器。"
  (message "\n=== 示例4：子选择器 ===")
  
  ;; 直接子元素
  (let ((nodes (css-dom-query-selector-all example-dom-complex "body > header")))
    (message "子选择器 'body > header': 找到 %d 个节点" (length nodes)))
  
  ;; 类的子元素
  (let ((nodes (css-dom-query-selector-all example-dom-complex ".content > article")))
    (message "类子选择器 '.content > article': 找到 %d 个文章" (length nodes))))

(defun example-dom-5-attribute-selectors ()
  "示例5：属性选择器。"
  (message "\n=== 示例5：属性选择器 ===")
  
  ;; 存在属性
  (let ((nodes (css-dom-query-selector-all example-dom-complex "[href]")))
    (message "属性存在 [href]: 找到 %d 个节点" (length nodes)))
  
  ;; 属性等于
  (let ((nodes (css-dom-query-selector-all example-dom-complex "[charset=\"utf-8\"]")))
    (message "属性等于 [charset=\"utf-8\"]: 找到 %d 个节点" (length nodes)))
  
  ;; 属性包含
  (let ((nodes (css-dom-query-selector-all example-dom-complex "[class*=\"menu\"]")))
    (message "属性包含 [class*=\"menu\"]: 找到 %d 个节点" (length nodes))))

;;; 样式操作示例

(defun example-dom-6-apply-styles ()
  "示例6：应用CSS样式。"
  (message "\n=== 示例6：应用样式 ===")
  
  (let ((dom (copy-tree example-dom-simple)))
    ;; 为所有段落设置样式
    (css-dom-apply-style dom "p" 
                         '((color . "blue") (font-size . "14px")))
    (message "已为所有 p 元素应用样式")
    
    ;; 为特定类设置样式
    (css-dom-apply-style dom ".highlight"
                         '((background-color . "yellow") (font-weight . "bold")))
    (message "已为 .highlight 元素应用样式")
    
    ;; 查看结果
    (let ((node (css-dom-query-selector dom "p.highlight")))
      (message "高亮段落的样式: %S" 
               (cdr (assq 'style (dom-attributes node)))))))

(defun example-dom-7-style-manipulation ()
  "示例7：样式操作。"
  (message "\n=== 示例7：样式操作 ===")
  
  (let ((dom (copy-tree example-dom-simple))
        (node nil))
    ;; 设置初始样式
    (setq node (css-dom-query-selector dom "#title"))
    (css-dom-set-styles node '((color . "red") (font-size . "24px")))
    (message "设置标题样式: %S" (css-dom-get-style node 'color))
    
    ;; 获取样式值
    (message "标题字体大小: %S" (css-dom-get-style node 'font-size))
    
    ;; 追加样式
    (css-dom-set-styles node '((margin . "10px")))
    (message "追加边距后: %S" 
             (cdr (assq 'style (dom-attributes node))))))

;;; 类操作示例

(defun example-dom-8-class-manipulation ()
  "示例8：类操作。"
  (message "\n=== 示例8：类操作 ===")
  
  (let ((dom (copy-tree example-dom-complex))
        (node nil))
    ;; 添加类
    (setq node (css-dom-query-selector dom "#header"))
    (message "原始类: %S" (cdr (assq 'class (dom-attributes node))))
    
    (css-dom-add-class node "animated")
    (message "添加类后: %S" (cdr (assq 'class (dom-attributes node))))
    
    ;; 移除类
    (css-dom-remove-class node "fixed")
    (message "移除类后: %S" (cdr (assq 'class (dom-attributes node))))
    
    ;; 检查类
    (message "有 'header' 类? %S" (css-dom-has-class node "header"))
    (message "有 'fixed' 类? %S" (css-dom-has-class node "fixed"))
    
    ;; 切换类
    (css-dom-toggle-class node "hidden")
    (message "切换后: %S" (cdr (assq 'class (dom-attributes node))))
    (css-dom-toggle-class node "hidden")
    (message "再次切换: %S" (cdr (assq 'class (dom-attributes node))))))

;;; 实用工具示例

(defun example-dom-9-extract-all-links ()
  "示例9：提取所有链接。"
  (message "\n=== 示例9：提取所有链接 ===")
  
  (let ((links (css-dom-query-selector-all example-dom-complex "a")))
    (message "找到 %d 个链接:" (length links))
    (dolist (link links)
      (let ((href (cdr (assq 'href (dom-attributes link))))
            (text (car (dom-strings link))))
        (message "  %s -> %s" text href)))))

(defun example-dom-10-find-active-items ()
  "示例10：查找激活状态的菜单项。"
  (message "\n=== 示例10：查找激活菜单项 ===")
  
  (let ((active-items (css-dom-query-selector-all example-dom-complex ".menu-item.active")))
    (message "找到 %d 个激活的菜单项:" (length active-items))
    (dolist (item active-items)
      (let ((link (css-dom-query-selector item "a")))
        (when link
          (message "  激活项: %S" (dom-texts link)))))))

(defun example-dom-11-modify-all-articles ()
  "示例11：修改所有文章样式。"
  (message "\n=== 示例11：修改所有文章 ===")
  
  (let ((dom (copy-tree example-dom-complex)))
    ;; 为所有文章添加边框
    (css-dom-apply-style dom "article"
                         '((border . "1px solid #ccc")
                           (padding . "10px")
                           (margin-bottom . "20px")))
    
    ;; 为特色文章添加特殊样式
    (css-dom-apply-style dom "article.featured"
                         '((background-color . "#fffacd")
                           (border-color . "#ffd700")))
    
    (let ((articles (css-dom-query-selector-all dom "article")))
      (message "已为 %d 篇文章应用样式" (length articles)))))

(defun example-dom-12-highlight-external-links ()
  "示例12：高亮外部链接。"
  (message "\n=== 示例12：高亮外部链接 ===")
  
  (let ((dom (copy-tree example-dom-complex)))
    ;; 查找所有链接并检查是否外部链接
    (let ((links (css-dom-query-selector-all dom "a[href]")))
      (dolist (link links)
        (let ((href (cdr (assq 'href (dom-attributes link)))))
          (when (string-match-p "^http" href)
            ;; 外部链接，添加样式
            (css-dom-set-styles link '((color . "blue")
                                       (text-decoration . "underline")))
            (message "高亮外部链接: %s" href)))))))

(defun example-dom-13-count-elements ()
  "示例13：统计各类元素数量。"
  (message "\n=== 示例13：统计元素 ===")
  
  (let ((stats (list
                (cons "总节点数" (length (css-dom-query-selector-all example-dom-complex "*")))
                (cons "div元素" (length (css-dom-query-selector-all example-dom-complex "div")))
                (cons "链接" (length (css-dom-query-selector-all example-dom-complex "a")))
                (cons "列表项" (length (css-dom-query-selector-all example-dom-complex "li")))
                (cons "文章" (length (css-dom-query-selector-all example-dom-complex "article")))
                (cons "有ID的元素" (length (css-dom-query-selector-all example-dom-complex "[id]")))
                (cons "有class的元素" (length (css-dom-query-selector-all example-dom-complex "[class]"))))))
    (dolist (stat stats)
      (message "  %s: %d" (car stat) (cdr stat)))))

(defun example-dom-14-style-navigation ()
  "示例14：样式化导航菜单。"
  (message "\n=== 示例14：样式化导航 ===")
  
  (let ((dom (copy-tree example-dom-complex)))
    ;; 设置导航容器样式
    (css-dom-apply-style dom ".navigation"
                         '((background-color . "#333")
                           (padding . "10px")))
    
    ;; 设置菜单样式
    (css-dom-apply-style dom ".menu"
                         '((list-style . "none")
                           (display . "flex")))
    
    ;; 设置菜单项样式
    (css-dom-apply-style dom ".menu-item"
                         '((margin-right . "15px")
                           (color . "white")))
    
    ;; 设置激活项特殊样式
    (css-dom-apply-style dom ".menu-item.active"
                         '((font-weight . "bold")
                           (border-bottom . "2px solid #fff")))
    
    (message "已完成导航样式化")))

(defun example-dom-15-create-theme ()
  "示例15：创建主题样式。"
  (message "\n=== 示例15：创建主题 ===")
  
  (let ((dom (copy-tree example-dom-complex)))
    ;; 深色主题
    (css-dom-apply-style dom "body"
                         '((background-color . "#1a1a1a")
                           (color . "#ffffff")))
    
    (css-dom-apply-style dom ".header"
                         '((background-color . "#2d2d2d")
                           (border-bottom . "1px solid #444")))
    
    (css-dom-apply-style dom ".content"
                         '((background-color . "#242424")
                           (padding . "20px")))
    
    (css-dom-apply-style dom "article"
                         '((background-color . "#2d2d2d")
                           (border . "1px solid #444")
                           (border-radius . "4px")
                           (padding . "15px")
                           (margin-bottom . "15px")))
    
    (css-dom-apply-style dom ".footer"
                         '((background-color . "#1a1a1a")
                           (border-top . "1px solid #444")
                           (text-align . "center")
                           (padding . "20px")))
    
    (message "已应用深色主题到整个页面")))

;;; 综合示例

(defun example-dom-16-comprehensive ()
  "示例16：综合应用。"
  (message "\n=== 示例16：综合应用 ===")
  
  (let ((dom (copy-tree example-dom-complex)))
    ;; 1. 查找所有文章
    (let ((articles (css-dom-query-selector-all dom "article")))
      (message "找到 %d 篇文章" (length articles))
      
      ;; 2. 为每篇文章添加索引类
      (cl-loop for article in articles
               for i from 1
               do (css-dom-add-class article (format "article-%d" i)))
      
      ;; 3. 为奇数文章添加特殊样式
      (css-dom-apply-style dom ".article-1, .article-3"
                           '((background-color . "#f5f5f5")))
      
      ;; 4. 为特色文章添加徽章
      (let ((featured (css-dom-query-selector dom ".featured")))
        (when featured
          (css-dom-add-class featured "badge")
          (css-dom-set-styles featured 
                              '((position . "relative")
                                (border-color . "#ffd700")))))
      
      ;; 5. 统计结果
      (message "处理完成:")
      (message "  - 添加了索引类")
      (message "  - 应用了奇偶样式")
      (message "  - 标记了特色文章"))))

;;; 运行所有示例

(defun run-all-dom-examples ()
  "运行所有CSS DOM选择器示例。"
  (interactive)
  (message "\n\n=====================================")
  (message "CSS DOM选择器示例集")
  (message "=====================================")
  
  (example-dom-1-basic-queries)
  (example-dom-2-combined-selectors)
  (example-dom-3-descendant-selectors)
  (example-dom-4-child-selectors)
  (example-dom-5-attribute-selectors)
  (example-dom-6-apply-styles)
  (example-dom-7-style-manipulation)
  (example-dom-8-class-manipulation)
  (example-dom-9-extract-all-links)
  (example-dom-10-find-active-items)
  (example-dom-11-modify-all-articles)
  (example-dom-12-highlight-external-links)
  (example-dom-13-count-elements)
  (example-dom-14-style-navigation)
  (example-dom-15-create-theme)
  (example-dom-16-comprehensive)
  
  (message "\n所有示例运行完成！")
  (message "查看 *Messages* 缓冲区查看详细输出。"))

;; 提供交互式命令
(defun css-dom-selector-run-examples ()
  "运行CSS DOM选择器的所有示例。
这会在*Messages*缓冲区中显示结果。"
  (interactive)
  (run-all-dom-examples)
  (switch-to-buffer "*Messages*")
  (goto-char (point-max)))

(provide 'css-dom-selector-examples)

;;; css-dom-selector-examples.el ends here

;;; css-dom-integration-example.el --- 集成示例：HTML处理实战 -*- lexical-binding: t; -*-

;; 这个文件展示了如何在实际场景中使用css-dom-selector.el

(require 'css-dom-selector)

;;; 场景1：网页抓取和信息提取

(setq-local lisp-indent-offset 2)
(defvar example-blog-html
  '(html nil
     (head nil
       (title nil "技术博客 - 最新文章"))
     (body nil
       (div ((id . "header") (class . "site-header"))
         (h1 ((class . "site-title")) "技术博客")
         (nav ((class . "main-nav"))
           (ul nil
             (li nil (a ((href . "/")) "首页"))
             (li nil (a ((href . "/archive")) "归档"))
             (li nil (a ((href . "/about")) "关于")))))
       (main ((id . "content"))
         (article ((class . "post") (data-id . "1"))
           (h2 ((class . "post-title"))
             (a ((href . "/posts/1")) "深入理解CSS选择器"))
           (div ((class . "post-meta"))
             (span ((class . "author")) "作者：张三")
             (span ((class . "date")) "2024-01-15"))
           (div ((class . "post-excerpt"))"CSS选择器是前端开发的基础...")
           (div ((class . "post-tags"))
             (a ((href . "/tags/css") (class . "tag")) "CSS")
             (a ((href . "/tags/frontend") (class . "tag")) "前端")))
         (article ((class . "post") (data-id . "2"))
           (h2 ((class . "post-title"))
             (a ((href . "/posts/2")) "Emacs Lisp编程指南"))
           (div ((class . "post-meta"))
             (span ((class . "author")) "作者：李四")
             (span ((class . "date")) "2024-01-14"))
           (div ((class . "post-excerpt"))
             "Emacs Lisp是一门强大的脚本语言...")
           (div ((class . "post-tags"))
             (a ((href . "/tags/emacs") (class . "tag")) "Emacs")
             (a ((href . "/tags/lisp") (class . "tag")) "Lisp"))))
       (aside ((id . "sidebar"))
         (div ((class . "widget"))
           (h3 nil "热门标签")
           (div ((class . "tag-cloud"))
             (a ((href . "/tags/css")) "CSS")
             (a ((href . "/tags/javascript")) "JavaScript")
             (a ((href . "/tags/emacs")) "Emacs"))))
       (footer ((id . "footer") (class . "site-footer"))
         (p nil "© 2024 技术博客. All rights reserved."))))
  "示例博客HTML结构。")

(defun extract-blog-posts (dom)
  "从博客DOM中提取所有文章信息。"
  (let ((articles (css-dom-query-selector-all dom "article.post"))
         (posts '()))
    (dolist (article articles)
      (let* ((title-link (css-dom-query-selector article ".post-title a"))
              (title (car (dom-strings title-link)))
              (url (cdr (assq 'href (dom-attributes title-link))))
              (author-node (css-dom-query-selector article ".author"))
              (author (car (dom-strings author-node)))
              (date-node (css-dom-query-selector article ".date"))
              (date (car (dom-strings date-node)))
              (excerpt-node (css-dom-query-selector article ".post-excerpt"))
              (excerpt (car (dom-strings excerpt-node)))
              (tag-nodes (css-dom-query-selector-all
                           article ".post-tags .tag"))
              (tags (mapcar (lambda (tag)
                              (car (dom-strings tag)))
                      tag-nodes)))
        (push (list :title title
                :url url
                :author author
                :date date
                :excerpt excerpt
                :tags tags)
          posts)))
    (nreverse posts)))

(defun demo-extract-posts ()
  "演示文章提取。"
  (interactive)
  (message "\n=== 提取博客文章 ===")
  (let ((posts (extract-blog-posts example-blog-html)))
    (message "找到 %d 篇文章:\n" (length posts))
    (dolist (post posts)
      (message "标题: %s" (plist-get post :title))
      (message "作者: %s" (plist-get post :author))
      (message "日期: %s" (plist-get post :date))
      (message "标签: %s" (string-join (plist-get post :tags) ", "))
      (message ""))))

;;; 场景2：主题切换

(defun apply-dark-theme (dom)
  "应用深色主题到博客DOM。"
  ;; 主体背景
  (css-dom-apply-style dom "body"
    '((background-color . "#1e1e1e")
      (color . "#d4d4d4")))
  
  ;; 头部
  (css-dom-apply-style dom ".site-header"
    '((background-color . "#2d2d30")
      (border-bottom . "1px solid #3e3e42")))
  
  ;; 文章卡片
  (css-dom-apply-style dom "article.post"
    '((background-color . "#252526")
      (border . "1px solid #3e3e42")
      (border-radius . "8px")
      (padding . "20px")
      (margin-bottom . "20px")))
  
  ;; 链接
  (css-dom-apply-style dom "a"
    '((color . "#569cd6")
      (text-decoration . "none")))
  
  ;; 标签
  (css-dom-apply-style dom ".tag"
    '((background-color . "#3e3e42")
      (color . "#cccccc")
      (padding . "4px 8px")
      (border-radius . "4px")
      (margin-right . "5px")
      (display . "inline-block")))
  
  ;; 页脚
  (css-dom-apply-style dom ".site-footer"
    '((background-color . "#2d2d30")
      (border-top . "1px solid #3e3e42")
      (text-align . "center")
      (padding . "20px"))))

(defun apply-light-theme (dom)
  "应用浅色主题到博客DOM。"
  ;; 主体背景
  (css-dom-apply-style dom "body"
    '((background-color . "#ffffff")
      (color . "#333333")))
  
  ;; 头部
  (css-dom-apply-style dom ".site-header"
    '((background-color . "#f8f9fa")
      (border-bottom . "1px solid #dee2e6")))
  
  ;; 文章卡片
  (css-dom-apply-style dom "article.post"
    '((background-color . "#ffffff")
      (border . "1px solid #dee2e6")
      (border-radius . "8px")
      (padding . "20px")
      (margin-bottom . "20px")
      (box-shadow . "0 2px 4px rgba(0,0,0,0.1)")))
  
  ;; 链接
  (css-dom-apply-style dom "a"
    '((color . "#007bff")
      (text-decoration . "none")))
  
  ;; 标签
  (css-dom-apply-style dom ".tag"
    '((background-color . "#e9ecef")
      (color . "#495057")
      (padding . "4px 8px")
      (border-radius . "4px")
      (margin-right . "5px")
      (display . "inline-block")))
  
  ;; 页脚
  (css-dom-apply-style dom ".site-footer"
    '((background-color . "#f8f9fa")
      (border-top . "1px solid #dee2e6")
      (text-align . "center")
      (padding . "20px"))))

(defun demo-theme-switching ()
  "演示主题切换。"
  (interactive)
  (message "\n=== 主题切换演示 ===")
  
  ;; 应用深色主题
  (let ((dom-dark (copy-tree example-blog-html)))
    (apply-dark-theme dom-dark)
    (message "深色主题已应用")
    (let ((body (css-dom-query-selector dom-dark "body")))
      (message "Body样式: %s" 
               (cdr (assq 'style (dom-attributes body))))))
  
  (message "")
  
  ;; 应用浅色主题
  (let ((dom-light (copy-tree example-blog-html)))
    (apply-light-theme dom-light)
    (message "浅色主题已应用")
    (let ((body (css-dom-query-selector dom-light "body")))
      (message "Body样式: %s" 
               (cdr (assq 'style (dom-attributes body)))))))

;;; 场景3：动态内容标记

(defun mark-external-links (dom)
  "为外部链接添加标记样式。"
  (let ((links (css-dom-query-selector-all dom "a[href]")))
    (dolist (link links)
      (let ((href (cdr (assq 'href (dom-attributes link)))))
        (when (and href (string-match-p "^http" href))
          (css-dom-add-class link "external-link")
          (css-dom-set-styles link
            '((color . "#e74c3c")
              (font-weight . "bold"))))))))

(defun highlight-recent-posts (dom days)
  "高亮最近DAYS天内的文章。"
  (let ((articles (css-dom-query-selector-all dom "article.post")))
    (dolist (article articles)
      ;; 简化演示：假设所有文章都是最近的
      (css-dom-add-class article "recent")
      (css-dom-set-styles article
        '((border-left . "4px solid #3498db")
          (padding-left . "16px"))))))

(defun add-reading-time (dom)
  "为每篇文章添加阅读时间标记。"
  (let ((articles (css-dom-query-selector-all dom "article.post")))
    (cl-loop for article in articles
             for i from 1
             do (let ((meta (css-dom-query-selector article ".post-meta")))
                  (when meta
                    ;; 添加阅读时间类（实际中会计算）
                    (css-dom-add-class meta "has-reading-time")
                    (css-dom-set-styles meta
                      '((display . "flex")
                        (gap . "15px")
                        (color . "#666"))))))))

(defun demo-content-marking ()
  "演示内容标记。"
  (interactive)
  (message "\n=== 动态内容标记 ===")
  
  (let ((dom (copy-tree example-blog-html)))
    ;; 标记外部链接
    (mark-external-links dom)
    (message "已标记外部链接")
    
    ;; 高亮最近文章
    (highlight-recent-posts dom 7)
    (message "已高亮最近7天的文章")
    
    ;; 添加阅读时间
    (add-reading-time dom)
    (message "已添加阅读时间标记")
    
    ;; 显示结果
    (let ((articles (css-dom-query-selector-all dom "article.recent")))
      (message "\n找到 %d 篇最近文章" (length articles)))))

;;; 场景4：内容过滤和转换

(defun filter-posts-by-tag (dom tag)
  "过滤出包含指定标签的文章。"
  (let ((articles (css-dom-query-selector-all dom "article.post"))
        (filtered '()))
    (dolist (article articles)
      (let ((tag-nodes (css-dom-query-selector-all article ".post-tags .tag")))
        (when (cl-some (lambda (tag-node)
                         (string= tag (car (dom-strings tag-node))))
                       tag-nodes)
          (push article filtered))))
    (nreverse filtered)))

(defun extract-navigation-menu (dom)
  "提取导航菜单结构。"
  (let ((nav-links (css-dom-query-selector-all dom ".main-nav a"))
        (menu '()))
    (dolist (link nav-links)
      (let ((text (car (dom-strings link)))
            (href (cdr (assq 'href (dom-attributes link)))))
        (push (cons text href) menu)))
    (nreverse menu)))

(defun generate-tag-cloud (dom)
  "生成标签云数据。"
  (let ((tags (make-hash-table :test 'equal)))
    ;; 统计标签出现次数
    (dolist (tag-node (css-dom-query-selector-all dom ".post-tags .tag"))
      (let ((tag-name (car (dom-strings tag-node))))
        (puthash tag-name (1+ (gethash tag-name tags 0)) tags)))
    ;; 转换为列表
    (let ((tag-list '()))
      (maphash (lambda (tag count)
                 (push (cons tag count) tag-list))
               tags)
      (sort tag-list (lambda (a b) (> (cdr a) (cdr b)))))))

(defun demo-content-filtering ()
  "演示内容过滤。"
  (interactive)
  (message "\n=== 内容过滤和转换 ===")
  
  ;; 按标签过滤
  (let ((css-posts (filter-posts-by-tag example-blog-html "CSS")))
    (message "包含 'CSS' 标签的文章: %d 篇" (length css-posts)))
  
  ;; 提取导航菜单
  (let ((menu (extract-navigation-menu example-blog-html)))
    (message "\n导航菜单:")
    (dolist (item menu)
      (message "  %s -> %s" (car item) (cdr item))))
  
  ;; 生成标签云
  (let ((tag-cloud (generate-tag-cloud example-blog-html)))
    (message "\n标签云:")
    (dolist (tag tag-cloud)
      (message "  %s: %d" (car tag) (cdr tag)))))

;;; 场景5：辅助功能增强

(defun add-accessibility-attributes (dom)
  "为元素添加辅助功能属性（示例）。"
  ;; 为导航添加role
  (let ((nav (css-dom-query-selector dom ".main-nav")))
    (when nav
      (css-dom-add-class nav "accessible-nav")))
  
  ;; 为文章添加semantic标记
  (dolist (article (css-dom-query-selector-all dom "article.post"))
    (css-dom-add-class article "semantic-article"))
  
  ;; 为标签添加标识
  (dolist (tag (css-dom-query-selector-all dom ".tag"))
    (css-dom-add-class tag "tag-badge")))

(defun optimize-for-mobile (dom)
  "优化DOM以适应移动端显示。"
  ;; 调整布局
  (css-dom-apply-style dom "body"
    '((max-width . "100%")
      (padding . "0 15px")))
  
  ;; 调整文章卡片
  (css-dom-apply-style dom "article.post"
    '((margin-bottom . "15px")
      (padding . "15px")))
  
  ;; 调整字体
  (css-dom-apply-style dom ".post-title"
    '((font-size . "1.5em")
      (line-height . "1.4")))
  
  ;; 隐藏侧边栏（移动端）
  (css-dom-apply-style dom "#sidebar"
    '((display . "none"))))

(defun demo-accessibility-enhancement ()
  "演示辅助功能增强。"
  (interactive)
  (message "\n=== 辅助功能增强 ===")
  
  (let ((dom (copy-tree example-blog-html)))
    ;; 添加辅助功能属性
    (add-accessibility-attributes dom)
    (message "已添加辅助功能属性")
    
    ;; 优化移动端
    (optimize-for-mobile dom)
    (message "已优化移动端显示")
    
    (let ((body (css-dom-query-selector dom "body")))
      (message "Body样式: %s" 
               (cdr (assq 'style (dom-attributes body)))))))

;;; 运行所有演示

(defun run-all-integration-demos ()
  "运行所有集成示例"。
  (interactive)
  (message "\n\n=====================================")
  (message "CSS DOM 集成示例演示")
  (message "=====================================")
  
  (demo-extract-posts)
  (demo-theme-switching)
  (demo-content-marking)
  (demo-content-filtering)
  (demo-accessibility-enhancement)
  
  (message "\n所有集成示例运行完成！")
  (message "查看 *Messages* 缓冲区查看详细输出。"))

(provide 'css-dom-integration-example)

;;; css-dom-integration-example.el ends here

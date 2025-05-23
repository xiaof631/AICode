

# Todo日志记录工具
## 概述
这是一个日志记录工具，用于记录和管理每日任务、计划和完成情况。整个功能页面分为几个主要部分，提供直观的日常工作管理体验。

## 界面布局
### 标题区
- 显示当天的日期（自动计算和显示）
- 格式为"yyyy年MM月dd日 星期几"
### 主体区（工字形布局）
主体区域分为四个主要部分：
 顶部区域
- 显示当天所有待办任务
- 支持添加和编辑功能
- 可设置不同颜色，用于标注任务的四象限分类：
  - 红色：重要且紧急
  - 蓝色：重要不紧急
  - 橙色：不重要但紧急
  - 灰色：不重要不紧急 中部左侧区域（当天计划）
- 显示当天计划的任务
- 包含时间区间（几点到几点）
- 显示任务时长
- 显示具体工作内容
- 按时间进行排序
- 支持并行任务标识 中部右侧区域（实际完成情况）
- 显示当天实际完成的任务
- 内容格式与左侧计划区域一致
- 可从左侧计划自动带入
- 也可自行添加工作时间区间和内容 底部区域（备注栏）
- 提供自由编辑的备注内容区域
- 可记录当天工作的其他相关信息
## 功能特点
### 预览功能
- 上述描述的页面为预览页，直观展示当天的工作情况
### 任务管理
- 支持添加、编辑和删除任务
- 任务可按四象限进行分类，用不同颜色标识优先级
### 时间计划
- 支持添加和编辑时间计划
- 自动按时间排序
- 支持并行任务标识，方便识别同时进行的工作
### 完成情况记录
- 可从计划自动带入完成情况
- 也可手动添加完成的工作
- 记录实际工作时间和内容
### 备注功能
- 提供自由编辑的备注区域
- 可记录当天工作的补充信息
## 数据模型
### 任务模型 (TodoTask)
- 标题
- 四象限分类
- 完成状态
- 创建时间
### 计划任务模型 (ScheduledTask)
- 标题
- 开始时间
- 结束时间
- 是否为并行任务
- 备注
### 完成任务模型 (CompletedTask)
- 标题
- 开始时间
- 结束时间
- 备注
- 关联的计划任务ID（如果有）
### 日志数据模型 (DailyLog)
- 日期
- 任务列表
- 计划任务列表
- 完成任务列表
- 备注
## 系统要求
- iOS 15.0+ 或 macOS 12.0+
- Xcode 13.0+
- Swift 5.5+
## 使用场景
这个日志记录工具适用于：

- 日常工作计划与记录
- 时间管理与任务追踪
- 工作效率分析
- 个人成长记录
通过这个工具，用户可以更好地规划每天的工作，记录实际完成情况，并进行反思和改进。


- 首页的四像限增加图标
- 首页增加复盘记录统计数据
- 复盘历史记录数据回写异常
- 任务需要有一个历史记录并回看数据功能
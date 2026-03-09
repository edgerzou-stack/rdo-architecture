# Codec 基础 RTL 组件库说明

## 1. 说明
本目录提供一套面向 codec IP 初版开发的基础 RTL 组件库，目标是作为真实 RTL 仓库的起始版本使用，而不是教材式示例。

本套代码统一遵循以下约定：

- 统一采用低有效异步复位 `rst_n`
- 统一采用 `valid/ready` 流接口风格
- 统一采用偏保守的 Verilog-2001 写法
- 优先保证可综合、接口清晰、便于后续 lint / assertion / testbench 扩展

建议将 include 路径指向：

```text
codec_base_rtl/rtl
```

## 2. 统一流接口约定
基础流接口命名如下：

- `in_valid / in_ready / in_data`
- `out_valid / out_ready / out_data`

本版基础库支持的常用 sideband：

- `*_last`
- `*_user`

如后续需要 SOP / EOP / ERR 等语义，推荐在 `user` 中统一编码，默认建议如下：

- `user[0]`：SOP
- `user[1]`：EOP
- `user[2]`：ERR

对应公共定义见 [codec_defs.vh](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_defs.vh)。

## 3. 各模块职责

### 3.1 公共定义与控制类
- [codec_defs.vh](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_defs.vh)
  统一状态编码、CSR 地址定义、控制位/状态位/错误位定义、sideband 建议约定。

- [codec_regfile.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_regfile.v)
  基础寄存器文件。提供控制寄存器、状态寄存器、IRQ 使能/状态/清除、性能计数器映射和错误状态读取接口。当前接口是简化 CSR 风格，便于后续外包 APB/AXI-Lite。

- [codec_ctrl.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_ctrl.v)
  codec 顶层控制状态机。支持 `IDLE/RUN/FLUSH/DONE/ERR` 等状态，并对 `start/stop/soft_reset/flush/error/op_done/pipe_empty` 做统一控制。

### 3.2 流控与缓存类
- [codec_pipe_reg.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_pipe_reg.v)
  单级 elastic pipeline register。用于标准握手级间隔离。

- [codec_skid_buffer.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_skid_buffer.v)
  skid buffer。用于打断长组合 `ready` 路径，在下游突然 backpressure 时吸收一个额外 beat。

- [codec_sync_fifo.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_sync_fifo.v)
  单时钟同步 FIFO，支持 `valid/ready` 接口、`full/empty/level` 状态输出。

- [codec_async_fifo.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_async_fifo.v)
  双时钟异步 FIFO，采用 Gray code 指针和双级同步器实现 CDC。

### 3.3 存储与地址类
- [codec_ram_sdp_wrapper.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_ram_sdp_wrapper.v)
  简单双口 RAM wrapper，提供 1 写 1 读边界，便于后续替换成 SRAM 宏或 FPGA RAM 原语。

- [codec_counter.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_counter.v)
  通用计数器，支持 `clear/load/enable/saturate/terminal count`。

- [codec_addr_gen.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_addr_gen.v)
  通用地址生成器，支持 `base_addr/stride/length`，适合 line / block / frame 搬运。

### 3.4 数据格式处理类
- [codec_packer.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_packer.v)
  窄位宽输入打包为宽位宽输出，支持 flush 吐出尾包，并输出 `valid_count/valid_mask`。

- [codec_unpacker.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_unpacker.v)
  宽位宽输入拆分为窄位宽输出，保证顺序和 backpressure 下状态一致性。

- [codec_width_conv.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_width_conv.v)
  位宽转换封装层。根据 `IN_W/OUT_W` 自动选择 pack / unpack / passthrough。

### 3.5 仲裁与任务调度类
- [codec_rr_arbiter.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_rr_arbiter.v)
  round-robin 仲裁器，输出 onehot grant 和 grant index。

- [codec_task_queue.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_task_queue.v)
  小型任务/描述符队列，适合缓存 frame/block/job 描述符。

### 3.6 调试与监控类
- [codec_perf_counter.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_perf_counter.v)
  统计 `cycle/stall_cycle/input_beat/output_beat/frame_done` 等指标。

- [codec_err_monitor.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_err_monitor.v)
  sticky 错误监控模块，用于统一收集 overflow / underflow / protocol_error / illegal_cfg 等错误。

### 3.7 顶层骨架示例
- [codec_top_stub.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_top_stub.v)
  最小可运行 codec IP 骨架。当前串接了 `regfile + ctrl + skid + pipe + sync_fifo + packer + perf + err_monitor`，用于说明控制通路和数据通路如何拼接。

## 4. 模块依赖关系
- `codec_top_stub` 依赖：
  `codec_defs`、`codec_regfile`、`codec_ctrl`、`codec_skid_buffer`、`codec_pipe_reg`、`codec_sync_fifo`、`codec_packer`、`codec_perf_counter`、`codec_err_monitor`

- `codec_task_queue` 依赖：
  `codec_sync_fifo`

- `codec_width_conv` 依赖：
  `codec_packer`、`codec_unpacker`

- 其余模块均可独立使用

## 5. 建议优先用于仿真联调的模块
建议优先从以下模块开始做 smoke test 和 corner case 验证：

- `codec_pipe_reg`
- `codec_skid_buffer`
- `codec_sync_fifo`
- `codec_packer`
- `codec_unpacker`
- `codec_ctrl`

原因：

- 这些模块覆盖了最核心的握手、背压、flush、边界计数和状态推进逻辑
- 也是后续真实 codec datapath 接入时最容易出 bug 的位置

完成上述模块的基本仿真后，再联调 [codec_top_stub.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_top_stub.v)，验证：

- CSR 控制路径是否通
- `start/flush/done/error` 状态是否正确
- 输入背压、输出背压、flush drain 行为是否符合预期
- IRQ / perf / error monitor 是否工作正常

## 6. 当前 top stub 的控制通路与数据通路

### 6.1 控制通路
控制通路结构如下：

```text
Host CSR
  -> codec_regfile
  -> codec_ctrl
  -> clear / accept_input / flush_active
  -> 各数据通路子模块
```

说明：

- `codec_regfile` 负责把软件写入转换成 `enable/start/stop/soft_reset/flush` 等控制信号
- `codec_ctrl` 负责状态机切换和运行期控制
- `ctrl_clear_pipeline`、`cmd_soft_reset` 用于清空数据通路内部缓存
- `ctrl_accept_input` 用于控制是否接受上游输入
- `ctrl_done_pulse`、`ctrl_error_pulse` 反馈给寄存器文件，形成 IRQ 状态

### 6.2 数据通路
数据通路结构如下：

```text
in_stream
  -> codec_skid_buffer
  -> codec_pipe_reg
  -> codec_sync_fifo
  -> codec_packer
  -> out_stream
```

说明：

- `codec_skid_buffer` 用于切断长组合 ready 路径
- `codec_pipe_reg` 用于标准级间寄存
- `codec_sync_fifo` 用于缓存和解耦突发流量
- `codec_packer` 用于演示位宽聚合和 flush 尾包输出
- 后续真实 codec 算法核可以插入在 `sync_fifo` 与 `packer` 之间，或者替换 `packer`

## 7. 后续接入真实 codec datapath 的扩展建议

### 7.1 视频 codec
可在当前骨架基础上插入：

- line buffer / block buffer
- transform / quant / inverse transform
- prediction / reconstruction
- entropy coder / decoder
- frame / tile / CTU / block 级任务调度

建议使用方式：

- `codec_task_queue` 存放 frame/block/job 描述符
- `codec_addr_gen` 生成 DDR / SRAM / line buffer 地址
- `codec_ram_sdp_wrapper` 作为行为级 RAM 边界，后续替换宏
- `codec_rr_arbiter` 用于多源访存或多任务发射仲裁
- `codec_sync_fifo` / `codec_async_fifo` 做级间解耦和跨时钟域

### 7.2 音频 codec
可在当前骨架基础上扩展：

- sample/frame 缓冲
- 窗函数、滤波器组、变换核
- 比特流打包/拆包
- 多通道数据流仲裁与重排

### 7.3 自定义压缩/解压 IP
对于非标准 codec，只要仍采用流式处理结构，本套基础组件可直接复用：

- 控制路径复用 `codec_regfile + codec_ctrl`
- 数据路径复用 `pipe/skid/fifo/width_conv`
- 错误与性能路径复用 `err_monitor + perf_counter`

## 8. 如果后续接 APB / AXI-Lite / AXI DMA，应从哪里切入

### 8.1 APB / AXI-Lite
最自然的切入点是 [codec_regfile.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_regfile.v) 的 `csr_*` 接口。

建议方式：

- 外层增加 `apb_to_csr_wrapper` 或 `axil_to_csr_wrapper`
- 在 wrapper 内完成：
  - 地址译码
  - 读写时序转换
  - byte strobe 支持
  - 访问错误响应

这样内部基础 RTL 不需要感知总线协议，只维持稳定 CSR 风格接口。

### 8.2 AXI DMA / AXI-Stream / Memory DMA
建议切入点：

- 流式数据接口对接在各模块的 `in_* / out_*`
- 需要跨时钟域时插入 `codec_async_fifo`
- 需要访存控制时由 `codec_task_queue + codec_addr_gen + arbiter` 管理 descriptor 和地址推进

如果后续要做完整 DMA 子系统，建议新增：

- AXI read request generator
- AXI write response tracker
- burst splitter / merger
- outstanding transaction scoreboard

## 9. 当前这版 RTL 的设计假设与局限性

### 9.1 参数和结构限制
- `codec_async_fifo` 要求 `DEPTH` 为 2 的幂，且至少为 2
- `codec_packer` 要求 `OUT_W % IN_W == 0`
- `codec_unpacker` 要求 `IN_W % OUT_W == 0`
- `codec_top_stub` 当前直接实例化 `codec_packer`，因此默认要求 `OUT_W >= IN_W` 且是整数倍关系

### 9.2 sideband 处理限制
- 当前 `codec_packer` 只保留 packed word 第一个 segment 的 `user`
- 如果后续需要对每个 segment 的 sideband 做聚合，需要在 packer 外层补 sideband merge 逻辑

### 9.3 FIFO / RAM 实现限制
- `codec_sync_fifo` 当前是行为级 FWFT 风格实现，适合作为基础库初版使用
- 若后续需要更深 FIFO、严格 SRAM 推断或工艺宏映射，建议单独替换为专用实现
- `codec_ram_sdp_wrapper` 当前只提供 wrapper 边界，最终读写同址行为应以目标 RAM 宏规格为准

### 9.4 CSR 实现限制
- `codec_regfile` 当前为 always-ready 的轻量风格
- 尚未加入 byte enable、权限控制、访问超时、总线错误返回等复杂总线语义
- 更适合作为内部标准 CSR 层，而不是直接暴露给 SoC 总线

### 9.5 顶层 stub 限制
- `codec_top_stub` 仅用于打通基础架构，不包含真实 codec 算法核
- 当前 `done` 判定以输出侧 `out_last` 握手作为示例事件，不代表最终产品级 codec 完成定义
- 真正项目中应将 `op_done_i` 替换为算法核或任务调度器的完成条件

## 10. 建议下一步工作
如果继续沿这版基础库推进，建议按以下顺序扩展：

1. 为 `pipe/skid/fifo/packer/unpacker/ctrl` 补一套基础 testbench
2. 增加 APB 或 AXI-Lite wrapper
3. 增加 descriptor 格式定义和 task scheduler
4. 增加 memory interface wrapper
5. 插入真实 codec datapath 子模块
6. 加 assertion、lint 规则和 CDC 检查约束

## 11. 文件清单
- [codec_defs.vh](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_defs.vh)
- [codec_regfile.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_regfile.v)
- [codec_ctrl.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_ctrl.v)
- [codec_pipe_reg.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_pipe_reg.v)
- [codec_skid_buffer.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_skid_buffer.v)
- [codec_sync_fifo.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_sync_fifo.v)
- [codec_async_fifo.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_async_fifo.v)
- [codec_ram_sdp_wrapper.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_ram_sdp_wrapper.v)
- [codec_counter.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_counter.v)
- [codec_addr_gen.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_addr_gen.v)
- [codec_packer.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_packer.v)
- [codec_unpacker.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_unpacker.v)
- [codec_width_conv.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_width_conv.v)
- [codec_rr_arbiter.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_rr_arbiter.v)
- [codec_task_queue.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_task_queue.v)
- [codec_perf_counter.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_perf_counter.v)
- [codec_err_monitor.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_err_monitor.v)
- [codec_top_stub.v](/Users/zouzhengting/Documents/编解码/编解码详细设计/codec_base_rtl/rtl/codec_top_stub.v)

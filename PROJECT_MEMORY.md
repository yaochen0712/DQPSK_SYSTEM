# Course Loopback 当前记忆

更新时间：2026-06-29

## 工程位置

- 工作目录：`E:\Workspace\course_loopback`
- 项目类型：Vivado FPGA / QPSK loopback 工程
- 当前没有依赖 git 状态来管理这次修改；如有用户未提交改动，不要回退。

## 已完成的核心修改

1. TX/RX 中间已经加入差分编码方案。
2. 原先按 I、Q 两路 bit 分别 XOR 的差分编码，已替换为 QPSK 符号级 DQPSK。
3. DQPSK 能抵消固定的 0/90/180/270 度相位旋转，因此比逐路差分更适合处理实际接收时本振相位差导致的 IQ 交换或符号旋转。
4. Gardner 判决处加入了简单幅度阈值，避免 ADC 噪声在无有效信号时持续触发后级卷积/Viterbi 解码。
5. 板上观察到 RX 解调后 I 与 TX 一致、Q 相对 TX 反相，因此在 RX 差分解码前加入 Q bit 取反修正。
6. TX 采样入口已拆成 72M 两拍同步模块和投票窗口模块，避免直接单点采样外部/异步输入。

## 关键文件

- `rtl/iq_differential_codec.sv`
  - 实现 QPSK 符号级差分编码/解码。
  - 当前映射：
    - `11 -> phase 0`
    - `01 -> phase 1`
    - `00 -> phase 2`
    - `10 -> phase 3`
  - TX：`next_phase = prev_phase + data_phase mod 4`
  - RX：`data_phase = current_phase - prev_phase mod 4`

- `rtl/tx_sample_coded.sv`
  - 发送端实例化 `iq_differential_encoder`。
  - `o_tst_IQ_data` 当前输出实际送往调制器的差分后 2bit 符号 `diff_coded_data`，方便和 RX 测试口直接比较。
  - 输入 `i_sample_bit` 先经过 `bit_sync_2ff` 两拍同步。
  - 当前使用 `sample_vote_filter` 代替单点采样。
  - 默认配置 `OVERSAMPLE_COEF=OVER_SAMPLE_COEF`、`VOTE_START=3`、`VOTE_LEN=7`。
  - 投票模块每 12 个 72M 时钟输出 1 个 voted bit 和 1 拍 `sample_en/o_sample_tick`，后级卷积/DQPSK valid 仍维持 6M。

- `rtl/bit_sync_2ff.sv`
  - 单 bit 两拍同步模块，用 72M `clk` 对外部/异步 bit 输入同步。

- `rtl/sample_tick_gen.sv`
  - 独立分频采样 tick 产生模块。
  - 参数 `SAMPLE_COEF` 控制 tick 周期，tick 为 1clk 宽度。
  - 当前 TX 主路径已由 `sample_vote_filter` 替代，保留该模块用于对比/回退。

- `rtl/sample_vote_filter.sv`
  - 72M 连续采样同步后的输入 bit。
  - 每 `OVERSAMPLE_COEF` 拍输出一次 voted bit。
  - 默认取中间 7/12 点多数表决：采样计数 3 到 9，`sum >= 4` 判 1。

- `rtl/rx_decode.sv`
  - 接收端实例化 `iq_differential_decoder`。

- `rtl/rx_top.v`
  - `qpsk_stream_demo` 输出先进入 `IQ_coded_stream_raw`。
  - 当前设置 `RX_INVERT_Q = 1'b1`，将 Q bit 取反后形成 `IQ_coded_stream`，再送入 `rx_decode`。
  - `o_tst_IQ_data` 当前输出修正后的 `IQ_coded_stream`。

- `rtl/gardner_ted.v`
  - 当前代码中 `DECISION_THRESHOLD = 20'd64`。
  - 可从 `20'd80` 起调，观察到滤波后的信号一般不超过10000。
  - `sync_flag <= samp_flag & decision_reliable`。

- `sim/tb_iq_differential_codec.sv`
  - 基础差分编解码测试。

- `sim/tb_dqpsk_rotation.sv`
  - 验证固定相位旋转下 DQPSK 可恢复。

- `sim/tb_dqpsk_iq_axis_correction.sv`
  - 验证 DQPSK 的边界条件：
    - 固定旋转属于 DQPSK 可恢复类型。
    - 单独 Q 反相属于镜像，不等价于固定旋转，直接送差分解码会出错。
    - Q 反相在差分解码前修正后可以恢复。
    - IQ 交换也不等价于固定旋转，直接送差分解码会出错。
    - IQ 交换在差分解码前交换回来后可以恢复。

- `sim/tb_gardner_threshold.sv`
  - 验证低幅度噪声不会通过判决阈值。

- `sim/tb_sample_sync_tick.sv`
  - 验证 `bit_sync_2ff` 两拍延迟。
  - 验证 `sample_tick_gen` 相邻 tick 间隔等于参数 `SAMPLE_COEF`。

- `sim/tb_sample_vote_filter.sv`
  - 验证 `sample_vote_filter` 在理想窗口和少量边沿扰动窗口下可正确多数表决。
  - 验证 voted valid 间隔等于 `OVERSAMPLE_COEF`。

## 已验证结果

- `tb_iq_differential_codec PASS`
- `tb_dqpsk_rotation PASS`
- `tb_gardner_threshold PASS`
- `cmd /c compile.bat` 已通过。
- 使用独立 snapshot 的 `xelab` / `xsim` loopback 仿真已通过。
- 之前默认 `elaborate.bat` 有一次失败，原因像是 Vivado/xsim snapshot 目录被 GUI 或残留进程锁住，不是 RTL 语法问题。
- 2026-06-28 新增 RX Q 反相修正后：
  - `cmd /c compile.bat` 通过。
  - 默认 `elaborate.bat` 因 `xsim.dir/tb_loopback_behav/xsim.type` 被占用失败，仍是 snapshot 写入锁问题。
  - 使用独立 snapshot `tb_loopback_qinv_behav` 的 `xelab` 通过。
  - `xsim tb_loopback_qinv_behav -tclbatch tb_loopback.tcl` 通过。
- 2026-06-28 DQPSK 链路复查：
  - `tb_iq_differential_codec PASS`。
  - `tb_dqpsk_rotation PASS`。
  - `tb_dqpsk_iq_axis_correction PASS`。
  - 新增 `tb_dqpsk_iq_axis_correction.sv` 到 `QPSK_ZYNQ.xpr` 和 `QPSK_ZYNQ.sim/sim_1/behav/xsim/tb_loopback_vlog.prj`。
  - 更新仿真源列表后，`cmd /c compile.bat` 通过。
  - 使用独立 snapshot `tb_loopback_chaincheck2_behav` 的 `xelab` 通过。
  - `xsim tb_loopback_chaincheck2_behav -tclbatch tb_loopback.tcl` 通过。
- 2026-06-29 TX 采样入口同步/分频拆分：
  - 新增 `bit_sync_2ff.sv`、`sample_tick_gen.sv`、`tb_sample_sync_tick.sv`。
  - `tb_sample_sync_tick` 曾在实现前因缺少模块展开失败，红灯符合预期。
  - `tb_sample_sync_tick PASS`。
  - 更新 `QPSK_ZYNQ.xpr` 和 `QPSK_ZYNQ.sim/sim_1/behav/xsim/tb_loopback_vlog.prj`。
  - `cmd /c compile.bat` 通过。
  - 使用独立 snapshot `tb_loopback_sample_sync_behav` 的 `xelab` 通过。
  - `xsim tb_loopback_sample_sync_behav -tclbatch tb_loopback.tcl` 通过。
- 2026-06-29 TX 采样入口切换为投票窗口：
  - 新增 `sample_vote_filter.sv` 和 `tb_sample_vote_filter.sv`。
  - `tb_sample_vote_filter` 曾在实现前因缺少 `sample_vote_filter` 展开失败，红灯符合预期。
  - `tb_sample_vote_filter PASS`。
  - `tx_sample_coded` 已由 `sample_tick_gen + sample_buffer` 切换为 `bit_sync_2ff + sample_vote_filter`。
  - 更新 `QPSK_ZYNQ.xpr` 和 `QPSK_ZYNQ.sim/sim_1/behav/xsim/tb_loopback_vlog.prj`。
  - `cmd /c compile.bat` 通过。
  - 使用独立 snapshot `tb_loopback_sample_vote_behav` 的 `xelab` 通过。
  - `xsim tb_loopback_sample_vote_behav -tclbatch tb_loopback.tcl` 通过。
- 2026-06-29 TX 采样入口切换为边沿锁相方案：
  - 新增 `rtl/sample_edge_sync.sv`：上升沿检测 → 等 `EDGE_DELAY`（默认4）拍采样 → 每 `OVERSAMPLE_COEF`（默认12）拍 free-run 采样；检测到新上升沿即重锁相。
  - `tx_sample_coded` 已由 `sample_vote_filter` 替换为 `sample_edge_sync`。
  - 新增 `sim/tb_sample_edge_sync.sv`，验证：首次上升沿触发锁相、free-run 间隔 = OVERSAMPLE_COEF、新上升沿重锁相后 free-run 间隔恢复。
  - 更新 `QPSK_ZYNQ.xpr` 和 `QPSK_ZYNQ.sim/sim_1/behav/xsim/tb_loopback_vlog.prj`。
  - `xvlog` 编译通过（EXIT:0）。
  - `tb_sample_edge_sync PASS`。

## 设计注意点

- DQPSK 的第一个符号依赖初始参考相位，通常会损失或不可信；当前 `rx_decode` 里已有 `CONV_WAIT_CYCLE`，可覆盖 Viterbi 启动阶段。
- 当前阈值是临时硬件调参起点：
  - 如果有效符号经常被拦掉，可降到 30
  - 如果空闲噪声仍会进入后级，可升到 150
- 如果板上仍解不出来，优先检查：
  - Costas/Gardner 是否稳定锁定。
  - 阈值是否导致 `sync_flag` 丢太多。
  - `CONV_WAIT_CYCLE` 是否足够长。
  - RX 端 `{sync_I, sync_Q}` bit 顺序是否与 TX 星座映射一致。
  - `RX_INVERT_Q` 是否符合当前 DDS/IP 的实际 Q 路极性；如果之后修改了 TX/RX sin 符号或 DDS 相位配置，这个参数可能需要改回 `1'b0`。
  - 如果物理链路表现为固定 0/90/180/270 度旋转，DQPSK 应能自动恢复；如果表现为 I 反相、Q 反相或 IQ 交换，需要在差分解码前先做对应坐标修正。
  - 两拍同步只能降低亚稳态传播概率，不能消除异步输入边沿相对 72M 采样时钟造成的量化抖动；如果 3M/BMC 边沿间隔出现 9/11 个 72M 周期这类不稳定，可能需要边沿恢复、过采样判决或时钟恢复，而不是只靠两拍同步。

## 后续可能优化

- 把 `DECISION_THRESHOLD` 做成顶层参数、AXI 寄存器或 ILA 可观察信号，方便上板调试。
- 增加前导码/同步字检测，可以更可靠地处理初始符号、锁定状态和误判。
- 如果需要更强鲁棒性，可考虑软判决 Viterbi 或基于训练序列的相位/象限校正。

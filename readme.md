# ZYNQ DQPSK Loopback 传输系统

基于 **Xilinx ZYNQ** 平台的 **QPSK/DQPSK** 数字通信环路（Loopback）FPGA 实现。

## 概述

本项目实现了一个完整的 QPSK 数字通信物理层环路，包含发送（TX）和接收（RX）两条链路。发送端对输入 bit 进行卷积编码、DQPSK 差分编码、成形滤波和 NCO 调制；接收端完成 Costas 载波同步、Gardner 定时同步、匹配滤波、DQPSK 差分解码和 Viterbi 卷积解码。系统采用的是自己的ZYNQ开发板，可以利用PL软核编写中频频率和配置外部时钟发生器控制系统频率。实际经过下板天线配合外部模块在433MHz射频验证传输SPDIF信号。

## 参考

感谢 https://github.com/lauchinyuan/FPGA_QPSK-modem# 的开源工程。本工程在此基础上添加了流控和修改规范了RTL语言，添加了调整中频的接口和更加全面的Costas环参数。

## 核心特性

- **DQPSK 差分编码** — 符号级差分编解码，可固定相位旋转
- **Gardner 定时同步** — 带幅度阈值判决，避免 ADC 噪声在无信号时触发后级解码
- **Costas 载波同步** — 闭环锁相环恢复载波
- **卷积编解码** — 约束长度 k=3 的卷积编码 + Viterbi 解码
- **发送采样入口** — 支持多种同步方案：两拍同步、投票滤波、边沿锁相
- **AXI-Lite 寄存器控制** — 自定义 IP 核用于参数动态配置

## 项目结构

```
├── rtl/                    # RTL 源文件
│   ├── tx_top.v            # 发送端顶层
│   ├── rx_top.v            # 接收端顶层
│   ├── rx_noflow_top.v     # 接收端顶层（无流控）
│   ├── tx_noflow_top.v     # 发送端顶层（无流控）
│   ├── qpsk_stream_modu.sv # QPSK 调制
│   ├── qpsk_stream_demo.sv # QPSK 解调
│   ├── iq_differential_codec.sv  # DQPSK 差分编解码
│   ├── conv_encoder_k3.sv        # 卷积编码器 (k=3)
│   ├── conv_decoder_k3.sv        # Viterbi 解码器 (k=3)
│   ├── costas_loopfilter_fix.sv  # Costas 环路滤波器
│   ├── gardner_sync.v            # Gardner 定时同步
│   ├── gardner_ted.v             # Gardner 定时误差检测
│   ├── phase_detector_fix.sv     # 鉴相器
│   ├── nco.v                     # NCO 数控振荡器
│   ├── interpolate_filter.v      # 内插滤波器
│   ├── iq_comb.v                 # IQ 合并
│   ├── iq_div_fix.sv             # IQ 分频
│   ├── serpar_trans.sv           # 串并转换
│   ├── parser_trans.sv           # 并串转换
│   ├── flow_control.sv           # 流控模块
│   ├── flow_control_elastic.sv   # 弹性缓冲流控
│   ├── AD9269_Trans.v            # ADC 接口
│   ├── extend.v                  # 位宽扩展
│   ├── tx_sample_coded.sv        # TX 采样入口（含同步/投票/边沿锁相）
│   ├── bit_sync_2ff.sv           # 两拍同步
│   ├── sample_vote_filter.sv     # 多数投票滤波
│   ├── sample_edge_sync.sv       # 边沿锁相同步
│   ├── sample_tick_gen.sv        # 分频采样 tick 产生
│   └── sample_vote_filter.sv     # 采样投票滤波
├── sim/                    # 仿真测试文件
│   ├── tb_loopback.sv            # 顶层环路测试
│   ├── tb_iq_differential_codec.sv   # 差分编解码测试
│   ├── tb_dqpsk_rotation.sv         # DQPSK 相位旋转测试
│   ├── tb_dqpsk_iq_axis_correction.sv # DQPSK 坐标修正测试
│   ├── tb_gardner_threshold.sv      # Gardner 阈值测试
│   ├── tb_sample_sync_tick.sv       # 同步 tick 测试
│   ├── tb_sample_vote_filter.sv     # 投票滤波测试
│   └── tb_sample_edge_sync.sv       # 边沿锁相测试
├── constrains/             # 约束文件
│   ├── loop.xdc            
│   ├── rx.xdc
│   └── tx.xdc
├── diy_ip/                 # 自定义 IP
│   ├── AXI_Lite_reg_Ctrl/  # AXI-Lite 寄存器控制 IP
│   ├── clk_divider/        # 时钟分频 IP
│   └── reset_control/      # 复位控制 IP
├── docs/                   # 文档
├── matlab/                 # MATLAB 辅助设计
│   ├── rccos_design.m      # 升余弦滤波器设计
│   └── *.coe               # 滤波器系数文件
├── QPSK_ZYNQ.xpr           # Vivado 工程文件
└── readme.md
```

## 关键模块说明

### DQPSK 差分编解码 (`iq_differential_codec.sv`)

采用 QPSK 符号级差分编码，映射关系：

| 输入数据 | 相位变化 |
|---------|---------|
| 11      | 0°      |
| 01      | 90°     |
| 00      | 180°    |
| 10      | 270°    |

- **编码**：`next_phase = prev_phase + data_phase (mod 4)`
- **解码**：`data_phase = current_phase - prev_phase (mod 4)`

DQPSK 可自动抵消接收端本振相位差导致的 0°/90°/180°/270° 固定旋转，但 IQ 交换和单路反相需在解码前做坐标修正。

### Gardner 定时同步

- 带幅度阈值判决（`DECISION_THRESHOLD`），默认 64
- 信号幅度低于阈值时 `sync_flag` 不置位，避免噪声触发后级解码
- 阈值可通过顶层参数或 AXI 寄存器调整

### 发送采样入口

TX 采样入口先后迭代了三种方案：

1. **两拍同步** (`bit_sync_2ff`) — 降低亚稳态
2. **投票滤波** (`sample_vote_filter`) — 每 12 个 72M 时钟多数表决
3. **边沿锁相** (`sample_edge_sync`) — 上升沿检测 + 锁相 free-run 采样（当前方案）

## 仿真验证

所有仿真测试均已通过：

| 测试文件 | 验证内容 |
|---------|---------|
| `tb_loopback` | 顶层环路联合仿真 |
| `tb_iq_differential_codec` | 差分编解码基础功能 |
| `tb_dqpsk_rotation` | 固定相位旋转下 DQPSK 可恢复 |
| `tb_dqpsk_iq_axis_correction` | IQ 交换/反相的坐标修正 |
| `tb_gardner_threshold` | 低幅度噪声被阈值拦截 |
| `tb_sample_sync_tick` | 两拍同步 + 分频 tick |
| `tb_sample_vote_filter` | 多数投票正确性 |
| `tb_sample_edge_sync` | 边沿锁相与重锁相 |

## 设计注意

- DQPSK 第一个符号依赖初始参考相位，通常不可信；`rx_decode` 中 `CONV_WAIT_CYCLE` 可覆盖 Viterbi 启动阶段
- `RX_INVERT_Q` 参数补偿板上 Q 路极性反转；若修改了 TX/RX sin 符号或 DDS 相位配置，可能需要改回 `1'b0`
- 两拍同步只能降低亚稳态传播概率，不能消除量化抖动；需边沿恢复或时钟恢复的场景建议使用 `sample_edge_sync`

## 开发环境

- **EDA 工具**：Xilinx Vivado
- **目标平台**：ZYNQ-7000 系列
- **仿真器**：XSIM (Vivado Simulator)
- **辅助设计**：MATLAB（滤波器系数生成）

## License

本项目仅供学习研究使用。



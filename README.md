# VVC RDO Architecture Design

![Architecture](https://img.shields.io/badge/Hardware-Architecture-3b82f6?style=for-the-badge)
![VVC RDO](https://img.shields.io/badge/VVC-RDO_Transform-ec4899?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Active-10b981?style=for-the-badge)

Welcome to the **Ultimate RDO Architecture Design** repository. This repository serves as a centralized hub for modern, web-based hardware design specifications and workflow dashboards. 

All documentation is generated and hosted statically via GitHub Pages, ensuring an interactive, highly readable, and zero-drag "Geek Dashboard" experience for hardware engineers.

## 📖 Live Document Links (GitHub Pages)

You can directly access the interactive online documentation via the following links:

### 🌟 1. [Top-Level Architecture Dashboard](https://edgerzou-stack.github.io/rdo-architecture/html/index.html)
- **Target Audience:** Architects, Project Managers, and System Engineers.
- **Content:** An overview of the entire RDO Hardware Architecture Workflow (WF4, WF8, WF16, WF32, WF64) and high-level RDOQ budgets.

### 🔬 2. [VVC RDO Transform Core Detailed Design](https://edgerzou-stack.github.io/rdo-architecture/html/vvc_rdo_transform_dashboard_interactive.html)
- **Target Audience:** RTL Designers, Verification Engineers.
- **Content:** The highly detailed design specification for the Transform Core Module.
- **Highlights:**
  - Auto-stretching, zero-drag Mermaid hierarchy graphs.
  - Interactive Git-versioned Markdown content.
  - Responsive dynamic hardware matrix tables (up to 32x32) perfectly scaled for the viewport.
  - Z-shaped interactive SVG hardware pipelines.

### ⚡ 3. [HMVP RDO Pipeline Optimization](https://edgerzou-stack.github.io/rdo-architecture/html/HMVP_RDO_Pipeline_Optimization.html)
- **Target Audience:** Core RDO Architects, RTL Designers.
- **Content:** Deep architectural analysis breaking the strict algorithmic feedback loop of HMVP. Explains why "Pipelined Delayed Update" provides zero-bubble throughput and optimal BD-Rate.

### 🧮 4. [RDOQ Hardware Optimization Pipeline](https://edgerzou-stack.github.io/rdo-architecture/html/rdoq_hardware_dashboard.html)
- **Target Audience:** RTL Designers, RDOQ Algorithm Engineers.
- **Content:** RDOQ algorithm principles and hardware optimization strategies in a two-chapter interactive dashboard.
- **Chapter 1 — Algorithm (three-part layout):**
  - **1.1** Overall process (nested scan, data hazard, candidate levels, **decision-tree example**, fixed-point Cost formula)
  - **1.2** **Dcost** — transform-domain SSE, dequant error, Parseval equivalence
  - **1.3** **Bincost** — CABAC 4-step chain, ctxInc, Context_Array, Entropy_LUT build & lookup (worked example)
- **Chapter 2 — Hardware Optimization:** Pruning, Fast/Slow loop, static context, Two-Stage, Luma-Chroma bypass, 4×4 parallel decoupling
- **Assets:** `rdoq_decision_tree.png`, `rdoq_dcost.png`, `rdoq_entropy_lut.png`, `rdoq_formula.png`, and supporting diagrams under `html/`

### 🚀 5. [CABAC Intra/Inter Cost Hardware Parsing](https://edgerzou-stack.github.io/rdo-architecture/html/intra_inter_scabac_dashboard.html)
- **Target Audience:** RTL Designers, Algorithm Engineers.
- **Content:** Deep dive into HEVC Intra/Inter mode probability state machines, LUT lookups, and hardware architectures. 
- **Highlights:**
  - Python Graphviz pre-rendered SVG architecture topologies (eliminating client-side rendering artifacts and improving stability).
  - Strict C-Model cost step-by-step verification without arbitrary assumptions.
  - Objective exploration of hardware DDR bandwidth constraints vs algorithmic DPB reference lists.

### 🚰 6. [Rate Control & Virtual Buffer Architecture](https://edgerzou-stack.github.io/rdo-architecture/html/rate_control_dashboard.html)
- **Target Audience:** RTL Designers, Firmware Engineers, System Architects.
- **Content:** Demystifying the rate control (RC) closed-loop system, from HRD Virtual Buffer concepts to C-Model Bit Allocation (`targetPicSize`) and Linear Regression R-Q updates.
- **Highlights:**
  - Python Graphviz pre-rendered SVG dataflows illustrating RC allocation logic without Mermaid.
  - Explanation of the "Intra Bit Stealing" phenomenon and scene change model resets.
  - Conceptual "Water Pipe and Reservoir" economic analogy for RC.


## 🛠️ Repository Philosophy

This repository is designed to be **clean and purely web-facing**. We embrace the following principles:
- **Only Track HTML:** We exclusively track `.html` output files in Git to keep the repository extremely clean. All intermediate Excel, Word, or Markdown scripts remain on the local machine.
- **Zero Horizontal Scrolling:** All diagrams and tables are designed using a strict 100% relative width or dynamic dimensional sizing rule to ensure 0-drag readability across any display.
- **Hardware UI/UX:** We bring modern Web UI principles (glassmorphism, dark mode, high-contrast alerts) into Hardware Specification viewing.


---
*Maintained by the RDO Core Design Team.*

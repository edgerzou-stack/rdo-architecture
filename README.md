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

### 🎨 4. [Intra Prediction Architecture & MD/RDO Decoupling](https://edgerzou-stack.github.io/rdo-architecture/html/intra_prediction_architecture.html)
- **Target Audience:** Core Intra Architects, Algorithm Engineers.
- **Content:** Comprehensive analysis of Luma/Chroma decision loops, MD vs RDO pipeline decoupling, and advanced hardware bottleneck resolutions (MPM freeze, CCLM bypass, 4x4 handling).

## 🛠️ Repository Philosophy

This repository is designed to be **clean and purely web-facing**. We embrace the following principles:
- **Only Track HTML:** We exclusively track `.html` output files in Git to keep the repository extremely clean. All intermediate Excel, Word, or Markdown scripts remain on the local machine.
- **Zero Horizontal Scrolling:** All diagrams and tables are designed using a strict 100% relative width or dynamic dimensional sizing rule to ensure 0-drag readability across any display.
- **Hardware UI/UX:** We bring modern Web UI principles (glassmorphism, dark mode, high-contrast alerts) into Hardware Specification viewing.


---
*Maintained by the RDO Core Design Team.*

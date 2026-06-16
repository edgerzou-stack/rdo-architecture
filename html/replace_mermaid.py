import re

filepath = 'intra_inter_scabac_dashboard.html'
with open(filepath, 'r') as f:
    content = f.read()

# Replace block 1: MPM Tree
pattern1 = re.compile(r'<div class="mermaid">\s*graph TD\s*Start\[获取左侧模式.*?</div>', re.DOTALL)
replacement1 = '<div style="text-align: center; margin: 20px 0;"><img src="mpm_tree.svg" alt="MPM Tree" style="max-width: 100%; height: auto;"></div>'
content = pattern1.sub(replacement1, content)

# Replace block 2: Intra Flow
pattern2 = re.compile(r'<div class="mermaid">\s*graph LR\s*A\[当前块 Intra 模式.*?</div>', re.DOTALL)
replacement2 = '<div style="text-align: center; margin: 20px 0;"><img src="intra_flow.svg" alt="Intra Flow" style="max-width: 100%; height: auto;"></div>'
content = pattern2.sub(replacement2, content)

# Replace block 3: Inter Mode Tree
pattern3 = re.compile(r'<div class="mermaid">\s*graph TD\s*Start\[进入 Inter 预测块.*?</div>', re.DOTALL)
replacement3 = '<div style="text-align: center; margin: 20px 0;"><img src="inter_mode_tree.svg" alt="Inter Mode Tree" style="max-width: 100%; height: auto;"></div>'
content = pattern3.sub(replacement3, content)

# Replace block 4: MVD Flow
pattern4 = re.compile(r'<div class="mermaid">\s*graph TD\s*MVD\[输入的 MVD.*?</div>', re.DOTALL)
replacement4 = '<div style="text-align: center; margin: 20px 0;"><img src="mvd_flow.svg" alt="MVD Flow" style="max-width: 100%; height: auto;"></div>'
content = pattern4.sub(replacement4, content)

# Replace block 5: DPB Arch
pattern5 = re.compile(r'<div class="mermaid"[^>]*>\s*graph LR\s*subgraph L0\["List 0.*?</div>', re.DOTALL)
replacement5 = '<div style="text-align: center; margin: 20px 0; background: white; padding: 15px; border-radius: 8px;"><img src="dpb_arch.svg" alt="DPB Arch" style="max-width: 100%; height: auto;"></div>'
content = pattern5.sub(replacement5, content)

# Replace block 6: SoC DDR Arch
pattern6 = re.compile(r'<div class="mermaid"[^>]*>\s*graph LR\s*subgraph External\["外部存储.*?</div>', re.DOTALL)
replacement6 = '<div style="text-align: center; margin: 20px 0; background: white; padding: 15px; border-radius: 8px;"><img src="soc_ddr_arch.svg" alt="SoC DDR Arch" style="max-width: 100%; height: auto;"></div>'
content = pattern6.sub(replacement6, content)

with open(filepath, 'w') as f:
    f.write(content)

print("Replaced all Mermaid blocks with SVG images.")
